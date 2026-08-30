import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';

/// Aggregated totals for a period, computed from the order journal.
class PeriodStats {
  final double revenue;
  final int orderCount;
  final int itemCount;

  const PeriodStats({
    required this.revenue,
    required this.orderCount,
    required this.itemCount,
  });

  double get avgOrderValue => orderCount == 0 ? 0 : revenue / orderCount;
}

/// One point on the revenue-over-time series (bucketed per local day).
class DailyRevenue {
  final DateTime day;
  final double revenue;
  final int orderCount;

  const DailyRevenue({
    required this.day,
    required this.revenue,
    required this.orderCount,
  });
}

/// Ranked product performance within a period (units sold, then revenue).
class ProductSold {
  final String productId;
  final String name;
  final int quantity;
  final double revenue;

  const ProductSold({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

/// Revenue and order counts bucketed by hour of day (local) — drives the
/// staffing heatmap and the Today revenue chart.
class HourBucket {
  final int hour;
  final int orderCount;
  final double revenue;

  const HourBucket({
    required this.hour,
    required this.orderCount,
    this.revenue = 0,
  });
}

/// Per-waiter sales totals within a period.
class WaiterSales {
  final String username;
  final double revenue;
  final int orderCount;

  const WaiterSales({
    required this.username,
    required this.revenue,
    required this.orderCount,
  });
}

/// Revenue and units grouped by product category (current catalog category,
/// falling back to "Other" for lines whose product no longer exists).
class CategoryRevenue {
  final String category;
  final double revenue;
  final int quantity;

  const CategoryRevenue({
    required this.category,
    required this.revenue,
    required this.quantity,
  });
}

/// `orders`/`order_items` writes bump [journalMutationProvider] so dashboard
/// aggregates recompute after every charge.
class JournalMutationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final journalMutationProvider = NotifierProvider<JournalMutationNotifier, int>(
  JournalMutationNotifier.new,
);

/// Read/write access to the persisted order journal plus the SQL aggregate
/// queries that power the admin dashboard and reports.
class OrderJournalRepository {
  final Database _db;

  /// Local-timezone offset in ms, applied so day bucketing matches the
  /// café's own clock rather than UTC.
  static final int _tzOffsetMs = DateTime.now().timeZoneOffset.inMilliseconds;

  const OrderJournalRepository(this._db);

  /// Next ticket number — `MAX(id) + 1` so numbers never collide across app
  /// sessions (the in-memory counter restarts at 1 on every launch).
  Future<int> nextOrderId() async {
    final rows = await _db.rawQuery(
      'SELECT IFNULL(MAX(id), 0) + 1 AS next_id FROM orders',
    );
    return (rows.first['next_id'] as num).toInt();
  }

  /// Next per-day [`order_number`](OrderRecord.orderNumber) for [at]'s local
  /// day.
  ///
  /// ### Why the counter table (and not `MAX(order_number) + 1`)
  /// A `MAX()+1` scan on `orders` is neither atomic nor index-backed for this
  /// exact purpose, and two concurrent orders could hand out the same number.
  /// `order_counters` keeps one row per day: "increment, then read" is a
  /// single serialized transaction, so the number is unique even under
  /// concurrent charges. This is the only code path that touches
  /// `order_counters` — never bypass it with direct inserts elsewhere.
  Future<int> nextOrderNumber(DateTime at) async {
    return _db.transaction((txn) => _claimOrderNumber(txn, at));
  }

  /// Shares [at]'s local day as `YYYY-MM-DD` (the `order_counters` key).
  static String _dayKey(DateTime at) {
    final local = at.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  /// The atomic "increment counter, then read" sequence. Must run inside a
  /// transaction (either its own or `addOrder`'s) so the two statements can
  /// never interleave with a concurrent order.
  static Future<int> _claimOrderNumber(
    DatabaseExecutor txn,
    DateTime at,
  ) async {
    final key = _dayKey(at);
    await txn.rawInsert(
      'INSERT INTO order_counters (date, last_number) VALUES (?, 1) '
      'ON CONFLICT(date) DO UPDATE SET last_number = last_number + 1',
      [key],
    );
    final rows = await txn.rawQuery(
      'SELECT last_number FROM order_counters WHERE date = ?',
      [key],
    );
    return (rows.first['last_number'] as num).toInt();
  }

  /// Persists one completed order and its line items in a single transaction.
  ///
  /// When [OrderRecord.orderNumber] is `0` a fresh number is claimed from
  /// [nextOrderNumber] inside this same transaction, so number assignment and
  /// row insert can never disagree. Returns the record with the assigned
  /// number so callers can display it (kitchen ticket, receipt) immediately.
  Future<OrderRecord> addOrder(OrderRecord order) async {
    return _db.transaction((txn) async {
      final number = order.orderNumber == 0
          ? await _claimOrderNumber(txn, order.createdAt)
          : order.orderNumber;
      await txn.insert('orders', {
        'id': order.id,
        'created_at': order.createdAt.millisecondsSinceEpoch,
        'waiter_username': order.waiterUsername,
        'total': order.total,
        'order_number': number,
      });
      for (final OrderLineItem item in order.items) {
        await txn.insert('order_items', {
          'order_id': order.id,
          'product_id': item.productId,
          'name': item.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
        });
      }
      return order.copyWith(orderNumber: number);
    });
  }

  /// Revenue, order count and total units sold in `[from, to)`.
  Future<PeriodStats> statsBetween(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT IFNULL(SUM(o.total), 0) AS revenue, '
      'COUNT(*) AS orders, '
      'IFNULL(SUM(oi.items), 0) AS items '
      'FROM orders o '
      'LEFT JOIN ('
      '  SELECT order_id, SUM(quantity) AS items '
      '  FROM order_items GROUP BY order_id'
      ') oi ON oi.order_id = o.id '
      'WHERE o.created_at >= ? AND o.created_at < ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    final row = rows.first;
    return PeriodStats(
      revenue: (row['revenue'] as num).toDouble(),
      orderCount: (row['orders'] as num).toInt(),
      itemCount: (row['items'] as num).toInt(),
    );
  }

  /// Per-local-day revenue series inside `[from, to)`, one bucket per matched
  /// day (missing days omitted).
  Future<List<DailyRevenue>> revenuePerDay(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT ((o.created_at + ?) / 86400000) AS day_key, '
      'IFNULL(SUM(o.total), 0) AS revenue, COUNT(*) AS orders '
      'FROM orders o '
      'WHERE o.created_at >= ? AND o.created_at < ? '
      'GROUP BY day_key ORDER BY day_key ASC',
      [_tzOffsetMs, from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return [
      for (final row in rows)
        DailyRevenue(
          day: DateTime.fromMillisecondsSinceEpoch(
            (row['day_key'] as num).toInt() * 86400000 - _tzOffsetMs,
          ),
          revenue: (row['revenue'] as num).toDouble(),
          orderCount: (row['orders'] as num).toInt(),
        ),
    ];
  }

  /// Best-selling products within `[from, to)`, ranked by units sold.
  Future<List<ProductSold>> topProducts(
    DateTime from,
    DateTime to, {
    int limit = 5,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT oi.product_id, oi.name, '
      'SUM(oi.quantity) AS quantity, '
      'SUM(oi.quantity * oi.unit_price) AS revenue '
      'FROM order_items oi '
      'JOIN orders o ON o.id = oi.order_id '
      'WHERE o.created_at >= ? AND o.created_at < ? '
      'GROUP BY oi.product_id, oi.name '
      'ORDER BY quantity DESC LIMIT ?',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch, limit],
    );
    return [
      for (final row in rows)
        ProductSold(
          productId: row['product_id'] as String,
          name: row['name'] as String,
          quantity: (row['quantity'] as num).toInt(),
          revenue: (row['revenue'] as num).toDouble(),
        ),
    ];
  }

  /// Revenue + order counts grouped by hour of day (local), for staffing
  /// decisions and the Today revenue chart.
  Future<List<HourBucket>> revenueByHour(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT CAST(STRFTIME(\'%H\', o.created_at / 1000, '
      '\'unixepoch\', \'localtime\') AS INTEGER) AS hour, '
      'IFNULL(SUM(o.total), 0) AS revenue, COUNT(*) AS orders '
      'FROM orders o '
      'WHERE o.created_at >= ? AND o.created_at < ? '
      'GROUP BY hour ORDER BY hour ASC',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return [
      for (final row in rows)
        HourBucket(
          hour: (row['hour'] as num).toInt(),
          orderCount: (row['orders'] as num).toInt(),
          revenue: (row['revenue'] as num).toDouble(),
        ),
    ];
  }

  /// Sales credited to each waiter, ranked by revenue.
  Future<List<WaiterSales>> salesByWaiter(DateTime from, DateTime to) async {
    final rows = await _db.rawQuery(
      'SELECT o.waiter_username AS username, '
      'IFNULL(SUM(o.total), 0) AS revenue, COUNT(*) AS orders '
      'FROM orders o '
      'WHERE o.created_at >= ? AND o.created_at < ? '
      'AND o.waiter_username IS NOT NULL AND o.waiter_username <> \'\' '
      'GROUP BY o.waiter_username '
      'ORDER BY revenue DESC',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return [
      for (final row in rows)
        WaiterSales(
          username: row['username'] as String,
          revenue: (row['revenue'] as num).toDouble(),
          orderCount: (row['orders'] as num).toInt(),
        ),
    ];
  }

  /// Revenue and units grouped by category. Category is read from the current
  /// `products` catalog via LEFT JOIN; lines whose product was deleted group
  /// under "Other" by falling back to the snapshot: since order_items has no
  /// category, `''` maps to "Other".
  Future<List<CategoryRevenue>> revenueByCategory(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _db.rawQuery(
      'SELECT CASE WHEN COALESCE(p.category, \'\') = \'\' '
      'THEN \'Other\' ELSE p.category END AS category, '
      'IFNULL(SUM(oi.quantity * oi.unit_price), 0) AS revenue, '
      'IFNULL(SUM(oi.quantity), 0) AS quantity '
      'FROM order_items oi '
      'JOIN orders o ON o.id = oi.order_id '
      'LEFT JOIN products p ON p.id = oi.product_id '
      'WHERE o.created_at >= ? AND o.created_at < ? '
      'GROUP BY category ORDER BY revenue DESC',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return [
      for (final row in rows)
        CategoryRevenue(
          category: row['category'] as String,
          revenue: (row['revenue'] as num).toDouble(),
          quantity: (row['quantity'] as num).toInt(),
        ),
    ];
  }
}

final orderJournalRepositoryProvider = FutureProvider<OrderJournalRepository>(
  (ref) async =>
      OrderJournalRepository(await ref.watch(appDatabaseProvider.future)),
);

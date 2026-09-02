/// Read-only queries that power the **Sales Log** screen and the *busiest
/// hours* heatmap.
///
/// Holds the shared `Database` instance like the other repositories, but only
/// ever runs `SELECT`s — the UI-facing read side of the order journal. There
/// is deliberately **no parallel sales table**: every figure here is computed
/// from `orders` / `order_items` / `order_refunds` / `staff` via the indexes
/// declared in `app_database.dart`, so nothing is duplicated.
///
/// ### Refunds in the log (§4 of improve.md)
/// Rows now net out any partial refund (`netTotal = line total − share of the
/// refund`) and carry a refund badge. Voided orders still **appear** in the
/// log (their line items stay intact by design) but are tagged so the admin
/// sees which rows were touched instead of the void being silently dropped.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';

/// Refund state of a sales-log row, used to pick the badge.
enum SalesRefundState {
  /// The order has not been refunded in any way.
  none,

  /// The order received a partial refund (its total was reduced).
  partial,

  /// The order was fully voided.
  voided,
}

/// One row of the Sales Log: a single order line with its order context.
///
/// The log lists *lines* (not orders), so it is a flat view of exactly what
/// was sold — one entry per product line on each order.
class SalesEntry {
  final int orderId;

  /// Human-friendly per-day number (`#007`); `0` for seed/historical rows
  /// whose order_number was never assigned — fall back to [orderId] then.
  final int orderNumber;

  final DateTime createdAt;

  /// Snapshot name from `order_items` — survives later product renames.
  final String productName;
  final int quantity;

  /// Line total = `quantity * unit_price` (snapshot price at charge time).
  final double lineTotal;

  /// The line's share of the order's partial refunds, subtracted from
  /// [lineTotal] to give [netTotal]. `0` when the order has no refund.
  final double lineRefund;

  /// This order's refund state (partial / voided / none) — drives the badge.
  final SalesRefundState refundState;

  /// Charging account, `null` for seed rows without attribution.
  final String? waiterUsername;

  /// Display name joined from `staff`; falls back to the username.
  final String? waiterName;

  const SalesEntry({
    required this.orderId,
    required this.orderNumber,
    required this.createdAt,
    required this.productName,
    required this.quantity,
    required this.lineTotal,
    this.lineRefund = 0,
    this.refundState = SalesRefundState.none,
    this.waiterUsername,
    this.waiterName,
  });

  /// Best display name for the Waiter column.
  String get waiter => waiterName ?? waiterUsername ?? '—';

  /// Net line value after subtracting this line's share of any partial
  /// refund. Never goes below zero.
  double get netTotal => (lineTotal - lineRefund).clamp(0, double.maxFinite);

  /// Parses one joined row from `getSales`.
  static SalesEntry fromRow(Map<String, Object?> row) {
    final lineTotal = (row['line_total'] as num).toDouble();
    final orderRefund = (row['order_refund'] as num).toDouble();
    final isVoided = (row['is_voided'] as num).toInt() != 0;
    final refundState = isVoided
        ? SalesRefundState.voided
        : orderRefund > 0
            ? SalesRefundState.partial
            : SalesRefundState.none;
    // A void refunds the whole order (net = 0 per line); a partial refund
    // leaves the corrected, already-reduced line value as its net.
    final lineRefund = isVoided ? lineTotal : 0.0;

    return SalesEntry(
      orderId: row['order_id'] as int,
      orderNumber: (row['order_number'] as num).toInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      productName: row['product_name'] as String,
      quantity: (row['quantity'] as num).toInt(),
      lineTotal: lineTotal,
      lineRefund: lineRefund,
      refundState: refundState,
      waiterUsername: row['waiter_username'] as String?,
      waiterName: row['waiter_name'] as String?,
    );
  }
}

/// Order count for one (local weekday × hour) pair — the heatmap's raw data.
class WeekdayHourCount {
  /// Local weekday with Monday = 0 ... Sunday = 6.
  final int weekday;

  /// Local hour of day, 0–23.
  final int hour;

  final int orders;

  const WeekdayHourCount({
    required this.weekday,
    required this.hour,
    required this.orders,
  });
}

/// Read-only sales queries (see the file dartdoc).
class SalesQueryRepository {
  final Database _db;

  const SalesQueryRepository(this._db);

  /// Filtered, paginated line-level sales history for the Sales Log.
  ///
  /// Every filter is optional. When provided they push into the SQL
  /// `WHERE`, which the indexes cover:
  /// * [from]/[to]  → `idx_orders_created_at` (window scan)
  /// * [productId]  → `idx_order_items_product_id`
  /// * [waiterUsername] → `idx_orders_waiter_username`
  ///
  /// `ORDER BY` is the same `created_at` index so the sort never rescans.
  /// Rows beyond [limit] are skipped via `OFFSET`, so the UI can "load more"
  /// without ever pulling the whole history into memory.
  ///
  /// Refund integration (§4 of improve.md): an aggregated `SUM` of the
  /// order's `order_refunds` is `LEFT JOIN`ed in (via
  /// `idx_order_refunds_order_id`) so each row carries the net refund state.
  /// Voided orders are deliberately **not** filtered out — their lines stay in
  /// the log for audit, but are flagged so the badge is shown.
  Future<List<SalesEntry>> getSales({
    DateTime? from,
    DateTime? to,
    String? productId,
    String? waiterUsername,
    int limit = 100,
    int offset = 0,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (from != null) {
      clauses.add('o.created_at >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      clauses.add('o.created_at < ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (productId != null) {
      clauses.add('oi.product_id = ?');
      args.add(productId);
    }
    if (waiterUsername != null) {
      clauses.add('o.waiter_username = ?');
      args.add(waiterUsername);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';

    final rows = await _db.rawQuery(
      'SELECT o.id AS order_id, '
      'o.created_at, o.order_number, oi.product_id, o.is_voided, '
      'oi.name AS product_name, oi.quantity, '
      '(oi.quantity * oi.unit_price) AS line_total, '
      'IFNULL(COALESCE(r.refund, 0), 0) AS order_refund, '
      'o.waiter_username, s.name AS waiter_name '
      'FROM order_items oi '
      'JOIN orders o ON o.id = oi.order_id '
      'LEFT JOIN ('
      '  SELECT order_id, SUM(amount_cents) / 100.0 AS refund '
      '  FROM order_refunds GROUP BY order_id'
      ') r ON r.order_id = o.id '
      'LEFT JOIN staff s ON s.username = o.waiter_username '
      '$where '
      'ORDER BY o.created_at DESC, o.id DESC, oi.id ASC '
      'LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );
    return rows.map(SalesEntry.fromRow).toList();
  }

  /// Order counts grouped by local weekday × hour inside `[from, to)` — the
  /// input for the busiest-hours heatmap.
  ///
  /// Bucketing happens in SQL (`'%w'`/`'%H'` on the local timestamp) instead
  /// of Dart-side grouping, and the date window rides `idx_orders_created_at`.
  /// Returns only (weekday, hour) pairs that actually have orders; the UI
  /// zero-fills the missing cells so the heatmap keeps a stable shape.
  /// SQLite's `%w` counts Sunday = 0; we remap to Monday = 0 so rows mirror
  /// the heatmap's Monday-first axis.
  ///
  /// Voided orders are excluded (§4 of improve.md) so a voided order doesn't
  /// inflate a busy-hour cell.
  Future<List<WeekdayHourCount>> ordersByWeekdayHour(
    DateTime from,
    DateTime to,
  ) async {
    final rows = await _db.rawQuery(
      'SELECT CAST(STRFTIME(\'%w\', created_at / 1000, '
      '\'unixepoch\', \'localtime\') AS INTEGER) AS weekday, '
      'CAST(STRFTIME(\'%H\', created_at / 1000, '
      '\'unixepoch\', \'localtime\') AS INTEGER) AS hour, '
      'COUNT(*) AS orders '
      'FROM orders '
      'WHERE is_voided = 0 '
      'AND created_at >= ? AND created_at < ? '
      'GROUP BY weekday, hour',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return [
      for (final row in rows)
        WeekdayHourCount(
          weekday: ((row['weekday'] as num).toInt() + 6) % 7,
          hour: (row['hour'] as num).toInt(),
          orders: (row['orders'] as num).toInt(),
        ),
    ];
  }
}

final salesQueryRepositoryProvider = FutureProvider<SalesQueryRepository>(
  (ref) async =>
      SalesQueryRepository(await ref.watch(appDatabaseProvider.future)),
);

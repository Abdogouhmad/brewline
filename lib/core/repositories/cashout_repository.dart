import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/cashout_record.dart';
import 'package:brewline/core/models/shift_summary.dart';

/// Read/write access to `cashout_logs` — the ledger of *finalized* shift
/// closes ($4 of the cashout spec) — plus the derived shift query both
/// waiter actions share.
///
/// ## Why this table exists
/// `cashout_logs` stores the manually counted cash and the variance it
/// produces. Those two figures have **no other source of truth** in the
/// schema — they exist only because a waiter typed them in at close time —
/// so unlike the Sales Log (a pure query over `orders`/`order_items`) this
/// is a genuine dedicated table.
///
/// ## The single write path
/// [logCashout] is the **only** method that ever inserts into `cashout_logs`.
/// Interim/preview shift report prints deliberately do **not** write here:
/// the shift is still open, so their order count/total could change, and
/// every preview row would leave the admin Cashout Logs screen with several
/// rows per shift, only one authoritative. Interim prints log an
/// `audit_events` row (`report_print`) instead.
class CashoutRepository {
  final Database _db;

  const CashoutRepository(this._db);

  /// A live, derived summary of [waiterUsername]'s current shift.
  ///
  /// Shift start = the waiter's most recent `login` audit event, falling back
  /// to the start of the current local day when the account has no recorded
  /// login (seed/historical data). [end] defaults to now and is overridable
  /// so callers can compute a cashout at a slightly earlier moment without
  /// moving "now" between the summary and the close row.
  Future<ShiftSummary> currentShiftSummary({
    required String waiterUsername,
    DateTime? end,
  }) async {
    final shiftEnd = (end ?? DateTime.now()).toLocal();
    final login = await _db.query(
      'audit_events',
      where: "event_type = 'login' AND actor = ?",
      whereArgs: [waiterUsername],
      orderBy: 'id DESC',
      limit: 1,
    );
    final shiftStart = login.isEmpty
        ? DateTime(shiftEnd.year, shiftEnd.month, shiftEnd.day)
        : DateTime.fromMillisecondsSinceEpoch(
            login.first['created_at'] as int,
          );

    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS orders, IFNULL(SUM(total), 0) AS revenue '
      'FROM orders '
      'WHERE waiter_username = ? AND created_at >= ? AND created_at < ?',
      [
        waiterUsername,
        shiftStart.millisecondsSinceEpoch,
        shiftEnd.millisecondsSinceEpoch,
      ],
    );
    final row = rows.first;
    return ShiftSummary(
      waiterUsername: waiterUsername,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      orderCount: (row['orders'] as num).toInt(),
      totalSalesCents: ((row['revenue'] as num).toDouble() * 100).round(),
    );
  }

  /// Finalizes a shift close: inserts the `cashout_logs` row **and** the
  /// `cashout` audit event in one transaction.
  ///
  /// The audit event is what closes the *derived* shift — there is no
  /// separate status flag (the app's convention that shift state is derived,
  /// never stored). Keeping both writes in the same transaction means the
  /// ledger can never show a cashout whose close marker failed, or vice
  /// versa. This is the authoritative, irreversible record of the shift.
  Future<void> logCashout(CashoutRecord record) async {
    await _db.transaction((txn) async {
      await txn.insert('cashout_logs', record.toRow());
      await txn.insert('audit_events', {
        'event_type': 'cashout',
        'actor': record.waiterUsername,
        'metadata': '{"orderCount":${record.orderCount},'
            '"totalSalesCents":${record.totalSalesCents},'
            '"cashCountedCents":${record.cashCountedCents},'
            '"cashVarianceCents":${record.cashVarianceCents}}',
        'created_at': record.createdAt.millisecondsSinceEpoch,
      });
    });
  }

  /// Filtered, paginated history of finalized shift closes, newest first.
  ///
  /// Every filter is optional and rides an index: [from]/[to] →
  /// `idx_cashout_logs_created_at`; [waiterUsername] /
  /// [waiterId] → `idx_cashout_logs_waiter_id`. Pages are bounded by [limit]
  /// (+ [offset]) so the admin screen can "load more" without materializing
  /// every close.
  Future<List<CashoutRecord>> getCashoutLogs({
    DateTime? from,
    DateTime? to,
    String? waiterUsername,
    String? waiterId,
    int limit = 100,
    int offset = 0,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (from != null) {
      clauses.add('created_at >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      clauses.add('created_at < ?');
      args.add(to.millisecondsSinceEpoch);
    }
    if (waiterUsername != null) {
      clauses.add('waiter_username = ?');
      args.add(waiterUsername);
    }
    if (waiterId != null) {
      clauses.add('waiter_id = ?');
      args.add(waiterId);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';

    final rows = await _db.rawQuery(
      'SELECT * FROM cashout_logs $where '
      'ORDER BY created_at DESC, id DESC LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );
    return rows.map(CashoutRecord.fromRow).toList();
  }
}

final cashoutRepositoryProvider = FutureProvider<CashoutRepository>(
  (ref) async => CashoutRepository(await ref.watch(appDatabaseProvider.future)),
);
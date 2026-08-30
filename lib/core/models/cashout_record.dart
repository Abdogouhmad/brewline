/// One finalized shift close as recorded in `cashout_logs`.
///
/// Written only by `CashoutRepository.logCashout()` — the single
/// authoritative write path for this table. It snapshots everything the
/// order journal *can't* reconstruct later: the physically counted cash and
/// the resulting variance, plus the order count/total at close time. Once
/// written a row never changes, so the admin Cashout Logs screen is a true
/// point-in-time record rather than a live aggregation.
class CashoutRecord {
  final int id;

  /// `staff.id` of the waiter who cashed out.
  final String waiterId;

  /// Username of the waiter (audit `actor` convention: `'admin'` or a staff
  /// username).
  final String waiterUsername;

  /// Display name snapshotted at close time — survives staff renames or
  /// deletion so the log never shows a dangling id.
  final String waiterName;

  /// `shift_start` — when the waiter's current shift began (derived from the
  /// latest open `login` event; no `shifts` table exists in this app).
  final DateTime shiftStart;

  /// `shift_end` — the moment of the cashout.
  final DateTime shiftEnd;

  final int orderCount;

  /// Gross sales in integer cents, converted from the REAL `orders.total`.
  final int totalSalesCents;

  /// Physically counted drawer cash in integer cents.
  final int cashCountedCents;

  /// `cash_counted_cents - total_sales_cents`.
  final int cashVarianceCents;

  final DateTime createdAt;

  const CashoutRecord({
    this.id = 0,
    required this.waiterId,
    required this.waiterUsername,
    required this.waiterName,
    required this.shiftStart,
    required this.shiftEnd,
    required this.orderCount,
    required this.totalSalesCents,
    required this.cashCountedCents,
    required this.cashVarianceCents,
    required this.createdAt,
  });

  /// Column map for SQLite writes (see the `cashout_logs` schema).
  Map<String, Object?> toRow() => {
    'waiter_id': waiterId,
    'waiter_username': waiterUsername,
    'waiter_name': waiterName,
    'shift_start': shiftStart.millisecondsSinceEpoch,
    'shift_end': shiftEnd.millisecondsSinceEpoch,
    'order_count': orderCount,
    'total_sales_cents': totalSalesCents,
    'cash_counted_cents': cashCountedCents,
    'cash_variance_cents': cashVarianceCents,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  /// Parses one row from the `cashout_logs` table.
  static CashoutRecord fromRow(Map<String, Object?> row) => CashoutRecord(
    id: row['id'] as int,
    waiterId: row['waiter_id'] as String,
    waiterUsername: row['waiter_username'] as String? ?? '',
    waiterName: row['waiter_name'] as String? ?? '',
    shiftStart: DateTime.fromMillisecondsSinceEpoch(row['shift_start'] as int),
    shiftEnd: DateTime.fromMillisecondsSinceEpoch(row['shift_end'] as int),
    orderCount: (row['order_count'] as num).toInt(),
    totalSalesCents: (row['total_sales_cents'] as num).toInt(),
    cashCountedCents: (row['cash_counted_cents'] as num).toInt(),
    cashVarianceCents: (row['cash_variance_cents'] as num).toInt(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );

  /// Total in the same display convention as the journal (`DH 123.45`).
  String get formattedTotalCents => totalSalesCents.toStringAsFixed(0);
}
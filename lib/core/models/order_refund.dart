/// One row of the `order_refunds` ledger.
///
/// Records a single partial or full refund against an order. Unlike an
/// `audit_events` metadata blob, this keeps the refund as structured,
/// queryable data (order id, amount, reason, admin) so it can be summed,
/// filtered by date and printed independently — the same reasoning that
/// justified a dedicated `cashout_logs` table.
class OrderRefund {
  final int id;

  /// The order being refunded.
  final int orderId;

  /// The admin account (`staff` id) who performed the refund.
  final String adminId;

  /// `'partial'` (a corrected order) or `'full'` (a voided order).
  final String refundType;

  /// Refunded amount in cents, always positive.
  final int amountCents;

  /// Required free-text paper trail (e.g. "wrong item entered").
  final String reason;

  final DateTime createdAt;

  const OrderRefund({
    required this.id,
    required this.orderId,
    required this.adminId,
    required this.refundType,
    required this.amountCents,
    required this.reason,
    required this.createdAt,
  });

  bool get isFull => refundType == 'full';

  /// Parses one row from the `order_refunds` table.
  static OrderRefund fromRow(Map<String, Object?> row) => OrderRefund(
    id: row['id'] as int,
    orderId: row['order_id'] as int,
    adminId: row['admin_id'] as String,
    refundType: row['refund_type'] as String,
    amountCents: (row['amount_cents'] as num).toInt(),
    reason: row['reason'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );
}

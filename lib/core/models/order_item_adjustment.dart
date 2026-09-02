/// A corrected quantity for a single line item during a partial refund.
///
/// Captures the *new* (reduced) quantity for an `order_items` row; the refund
/// amount is derived as `old_total − new_total`. Per the §2.1 decrease-only
/// constraint, [newQuantity] must always be `<` the item's original quantity
/// (or the item is removed entirely via [remove]) — the repository enforces
/// this so a refund can never increase an order total.
class OrderItemAdjustment {
  /// The `order_items.id` of the line being corrected.
  final int orderItemId;

  /// The item's original quantity (read at load time, used for validation
  /// and to compute the refunded amount).
  final int originalQuantity;

  /// The item's unit price at charge time (snapshot).
  final double unitPrice;

  /// The reduced quantity after the correction. Must be `>= 0` and `<`
  /// [originalQuantity].
  final int newQuantity;

  const OrderItemAdjustment({
    required this.orderItemId,
    required this.originalQuantity,
    required this.unitPrice,
    required this.newQuantity,
  });

  /// The amount refunded by this adjustment, in cents.
  int get refundedCents =>
      ((originalQuantity - newQuantity) * unitPrice * 100).round();
}

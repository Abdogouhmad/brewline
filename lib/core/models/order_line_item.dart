/// One product line on a persisted order.
///
/// Stores a denormalised `name` and `unitPrice` snapshot so reports keep
/// working after the product is renamed, repriced or deleted — the journal
/// never joins back to the live `products` table for history.
class OrderLineItem {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;

  const OrderLineItem({
    required this.productId,
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

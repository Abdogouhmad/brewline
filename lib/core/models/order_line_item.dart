/// One product line on a persisted order.
///
/// Stores a denormalised `name` and `unitPrice` snapshot so reports keep
/// working after the product is renamed, repriced or deleted — the journal
/// never joins back to the live `products` table for history.
class OrderLineItem {
  /// The `order_items` primary key. `0` when the item hasn't been persisted
  /// yet (e.g. items built in memory before [OrderJournalRepository.addOrder]);
  /// populated by reads so the refund flow can address specific line rows.
  final int id;

  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;

  const OrderLineItem({
    this.id = 0,
    required this.productId,
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

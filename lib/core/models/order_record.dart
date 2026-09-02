import 'order_line_item.dart';

/// A completed order as recorded in the order journal.
///
/// `id` is the ticket number handed to the customer; it doubles as the primary
/// key of the `orders` table so reports can cite it directly. `orderNumber` is
/// the human-friendly, per-day sequential number (`#007`) shown to customers;
/// it never changes once assigned. `waiterUsername` is the staff account that
/// charged the order (nullable for seed/historical data), and `items` holds
/// the line snapshots at charge time.
class OrderRecord {
  final int id;
  final DateTime createdAt;

  /// Per-day sequential number from `order_counters`. `0` means "assign one
  /// at insert time" (seed/historical rows keep 0).
  final int orderNumber;

  final String? waiterUsername;
  final double total;
  final List<OrderLineItem> items;

  /// True when the order has been fully voided (a full refund). The order and
  /// its items are never hard-deleted; the void is expressed through this flag
  /// and an `order_refunds` row so historical financial records stay intact.
  final bool isVoided;

  const OrderRecord({
    required this.id,
    required this.createdAt,
    this.orderNumber = 0,
    this.waiterUsername,
    required this.total,
    required this.items,
    this.isVoided = false,
  });

  OrderRecord copyWith({int? orderNumber}) => OrderRecord(
    id: id,
    createdAt: createdAt,
    orderNumber: orderNumber ?? this.orderNumber,
    waiterUsername: waiterUsername,
    total: total,
    items: items,
    isVoided: isVoided,
  );
}

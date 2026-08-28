import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/features/waiter/providers/product_provider.dart'
    show Product;

/// A single line on the current order: which [Product] and how many.
class OrderItem {
  final Product product;
  final int quantity;

  const OrderItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
  String get formattedTotal => formatPrice(totalPrice);

  OrderItem withQuantity(int quantity) =>
      OrderItem(product: product, quantity: quantity);
}

/// Sum of all line totals on [items].
double totalPriceOf(List<OrderItem> items) =>
    items.fold(0, (sum, item) => sum + item.totalPrice);

/// Total number of units across all lines on [items].
int totalUnitsOf(List<OrderItem> items) =>
    items.fold(0, (sum, item) => sum + item.quantity);

/// Terminal log tag for order events — grep-friendly when debugging.
const String _kOrderLogTag = '[brewline/order]';

/// Mutable cart state behind the Orders tab.
///
/// Tap a menu card to add its product; remove lines or clear from
/// OrdersPage. Charging logs the receipt summary to the terminal and
/// resets the cart. TODO: persist to database once orders are modeled.
class OrderController extends Notifier<List<OrderItem>> {
  @override
  List<OrderItem> build() => const [];

  /// Adds one unit of [product], bumping quantity if it's already on
  /// the order.
  void add(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    state = [
      for (final (i, item) in state.indexed)
        if (i == index) item.withQuantity(item.quantity + 1) else item,
      if (index == -1) OrderItem(product: product),
    ];
    _log('Added ${product.name} (${product.formattedPrice})');
  }

  /// Removes every unit of the line matching [productId].
  void remove(String productId) {
    final target = state
        .where((item) => item.product.id == productId)
        .firstOrNull;
    if (target == null) return;
    state = state.where((item) => item.product.id != productId).toList();
    _log('Removed ${target.product.name}');
  }

  /// Empties the order without charging.
  void clear() {
    _log('Cleared order of ${state.length} line(s)');
    state = const [];
  }

  /// Logs the charge summary to the terminal and resets the cart.
  ///
  /// TODO: replace logging with the real payment/receipt flow.
  void charge() {
    // Compute from [state] directly — reading orderTotalProvider here
    // would create a self-dependency cycle (it watches this notifier).
    final total = totalPriceOf(state);
    _log(
      'Charged ${formatPrice(total)} '
      '(${state.length} line(s), ${totalUnitsOf(state)} item(s))',
    );
    state = const [];
  }

  static void _log(String message) => debugPrint('$_kOrderLogTag $message');
}

final orderControllerProvider =
    NotifierProvider<OrderController, List<OrderItem>>(OrderController.new);

/// Running total of the current order.
final orderTotalProvider = Provider<double>(
  (ref) => totalPriceOf(ref.watch(orderControllerProvider)),
);

/// Header title of the Orders tab, e.g. `Order #12 · 3 items`.
final orderTitleProvider = Provider<String>((ref) {
  final number = ref.watch(orderNumberProvider);
  final units = totalUnitsOf(ref.watch(orderControllerProvider));
  return units > 1 ? 'Order #$number · $units items' : 'Order #$number';
});

/// Ticket number of the current order, shown as "Order #N".
///
/// Increments every time an order is charged so the next customer gets a
/// fresh number. TODO: derive from the database counter instead of memory.
class OrderNumberController extends Notifier<int> {
  /// Starting ticket number for this session.
  static const int initialOrderNumber = 1;

  @override
  int build() => initialOrderNumber;

  /// Moves to the next ticket number after a charge.
  void advance() => state++;
}

final orderNumberProvider = NotifierProvider<OrderNumberController, int>(
  OrderNumberController.new,
);

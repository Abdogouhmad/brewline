/// A menu product sold on the POS.
///
/// The single source of truth for the waiter menu and the admin Menu tab,
/// backed by the `products` SQLite table ([ProductRepository]).
///
/// `stockQuantity` tracks physical units on hand. A product is flagged as
/// low-stock by the admin dashboard when `stockQuantity > 0` and at or below
/// `lowStockThreshold`; `0` for either means stock is not being tracked.
class Product {
  final String id;
  final String name;

  /// Unit price in major currency units (e.g. DH).
  final double price;

  /// Asset path of the product photo under `assets/stack_imgs/`.
  final String imagePath;

  /// Free-text grouping used by the reports mix charts.
  final String category;

  /// Hidden from the waiter menu while `false`.
  final bool available;

  /// Units on hand; `0` means stock is not being tracked.
  final int stockQuantity;

  /// Below (or at) this quantity the dashboard raises a low-stock alert.
  final int lowStockThreshold;

  /// Soft-delete flag. Archived products leave the catalog/menu but their
  /// sales history (order_items line snapshots) stays intact.
  final bool isArchived;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    this.category = '',
    this.available = true,
    this.stockQuantity = 0,
    this.lowStockThreshold = 0,
    this.isArchived = false,
  });

  bool get isLowStock =>
      available && stockQuantity > 0 && stockQuantity <= lowStockThreshold;

  /// Column map for SQLite writes (see the `products` schema).
  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'price': price,
    'image_path': imagePath,
    'category': category,
    'available': available ? 1 : 0,
    'stock_quantity': stockQuantity,
    'low_stock_threshold': lowStockThreshold,
    'is_archived': isArchived ? 1 : 0,
  };

  /// Parses one row from the `products` table.
  static Product fromRow(Map<String, Object?> row) => Product(
    id: row['id'] as String,
    name: row['name'] as String,
    price: (row['price'] as num).toDouble(),
    imagePath: row['image_path'] as String? ?? '',
    category: row['category'] as String? ?? '',
    available: (row['available'] as int? ?? 1) == 1,
    stockQuantity: row['stock_quantity'] as int? ?? 0,
    lowStockThreshold: row['low_stock_threshold'] as int? ?? 0,
    isArchived: (row['is_archived'] as int? ?? 0) == 1,
  );
}

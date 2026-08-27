import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/features/waiter/data/providers/price_format.dart';

/// A menu product.
///
/// Temporary hard-coded catalog: swap [productsProvider] for a
/// database/stream-backed source when the product table is wired up —
/// nothing else needs to change since consumers only read this class.
class Product {
  final String id;
  final String name;

  /// Unit price in major currency units (e.g. dollars).
  final double price;

  /// Asset path of the product photo under `assets/stack_imgs/`.
  final String imagePath;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
  });

  String get formattedPrice => formatPrice(price);
}

/// Dummy menu used while binding to the real product table.
final productsProvider = Provider<List<Product>>((ref) {
  return const [
    Product(
      id: 'p-001',
      name: 'Espresso',
      price: 9.00,
      imagePath: 'assets/stack_imgs/expresso.jpg',
    ),
    Product(
      id: 'p-002',
      name: 'Coca-Cola',
      price: 15.00,
      imagePath: 'assets/stack_imgs/coca.jpg',
    ),
    Product(
      id: 'p-003',
      name: 'Milk',
      price: 9.00,
      imagePath: 'assets/stack_imgs/milk.jpg',
    ),
    Product(
      id: 'p-004',
      name: 'Tea',
      price: 9.00,
      imagePath: 'assets/stack_imgs/tea.jpg',
    ),
    Product(
      id: 'p-005',
      name: 'Water',
      price: 2.00,
      imagePath: 'assets/stack_imgs/water.png',
    ),
  ];
});

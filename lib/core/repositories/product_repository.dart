import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/product.dart';

/// `products` table mutations bump [productMutationProvider] so watchers
/// (waiter menu, admin dashboard) recompute when the catalog changes.
class ProductMutationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;

  /// Adds [amount] units back to the shelf for [id] and bumps the mutation
  /// counter so low-stock alerts and the catalog refresh.
  Future<void> restock(String id, int amount) async {
    final repo = await ref.read(productRepositoryProvider.future);
    await repo.restock(id, amount);
    state++;
  }

  /// Inserts a new product or updates an existing one (create/edit form).
  Future<void> upsert(Product product) async {
    final repo = await ref.read(productRepositoryProvider.future);
    await repo.upsert(product);
    state++;
  }

  /// Archives a product (soft delete). Sales history keeps its line snapshots
  /// and reports stay intact.
  Future<void> delete(String id) async {
    final repo = await ref.read(productRepositoryProvider.future);
    await repo.archive(id);
    state++;
  }

  /// Flips the in-service flag (waiter menu hides unavailable products).
  Future<void> setAvailable(String id, bool available) async {
    final repo = await ref.read(productRepositoryProvider.future);
    await repo.setAvailable(id, available);
    state++;
  }
}

final productMutationProvider = NotifierProvider<ProductMutationNotifier, int>(
  ProductMutationNotifier.new,
);

/// Writable handle to the `products` table. Construct once via
/// [productRepositoryProvider]; callers awaiting the provider get a shared
/// instance bound to the app database.
class ProductRepository {
  final Database _db;

  const ProductRepository(this._db);

  /// Every non-archived product, sorted alphabetically (case-insensitive).
  /// Archived products are excluded so the catalog/menu never resurrects a
  /// deleted item.
  Future<List<Product>> all() async {
    final rows = await _db.query(
      'products',
      where: 'is_archived = 0',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Product.fromRow).toList();
  }

  Future<Product?> byId(String id) async {
    final rows = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Product.fromRow(rows.first);
  }

  /// Available products whose tracked stock has dropped to (or below) their
  /// low-stock threshold, most-depleted first — drives the dashboard alert.
  Future<List<Product>> lowStock() async {
    final rows = await _db.query(
      'products',
      where:
          'available = 1 AND stock_quantity > 0 '
          'AND stock_quantity <= low_stock_threshold '
          'AND is_archived = 0',
      orderBy: 'stock_quantity ASC',
    );
    return rows.map(Product.fromRow).toList();
  }

  /// Inserts a new product or updates an existing one (matched by id).
  Future<void> upsert(Product product) async {
    final existing = await byId(product.id);
    if (existing == null) {
      await _db.insert(
        'products',
        product.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _db.update(
        'products',
        product.toRow(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }
  }

  /// Removes a product from the catalog via the `is_archived` soft-delete
  /// flag (never a hard `DELETE`): sales history keeps its line snapshots,
  /// and archived rows stay queryable if an unarchive flow is ever added.
  /// Filters on `is_archived`, a plain equality on a column with no index but
  /// a tiny cardinality — no index needed.
  Future<void> archive(String id) async {
    await _db.update(
      'products',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hard-removes the row and its history. Prefer [archive] — this only
  /// exists for tests and full-catalog resets.
  Future<void> delete(String id) async {
    await _db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setAvailable(String id, bool available) async {
    await _db.update(
      'products',
      {'available': available ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Decrements on-hand stock by the sold quantities, flooring at zero.
  /// Products with `stock_quantity = 0` (untracked) are left untouched.
  Future<void> decrementStock(Map<String, int> quantities) async {
    await _db.transaction((txn) async {
      for (final entry in quantities.entries) {
        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = '
          'MAX(stock_quantity - ?, 0) '
          'WHERE id = ? AND stock_quantity > 0',
          [entry.value, entry.key],
        );
      }
    });
  }

  /// Adds [amount] units back to a product's on-hand stock (restock action
  /// from the dashboard alert).
  Future<void> restock(String id, int amount) async {
    await _db.rawUpdate(
      'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
      [amount, id],
    );
  }
}

final productRepositoryProvider = FutureProvider<ProductRepository>(
  (ref) async => ProductRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Full catalog (including unavailable products) — the admin Menu tab and
/// the dashboard read this; it recomputes on any catalog write.
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(productMutationProvider);
  return (await ref.watch(productRepositoryProvider.future)).all();
});

/// Just the available products, for the waiter menu — updates live when the
/// admin hides, edits or adds to the catalog.
final menuProductsProvider = FutureProvider<List<Product>>((ref) async {
  final products = await ref.watch(allProductsProvider.future);
  return products.where((p) => p.available).toList();
});

/// Available products at risk of running out — recomputes on catalog writes.
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(productMutationProvider);
  return (await ref.watch(productRepositoryProvider.future)).lowStock();
});

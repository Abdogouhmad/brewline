/// CRUD for `ingredients` — the raw stock catalog. Stock-quantity mutations
/// are **not** here: this repository never touches `current_stock` or
/// `stock_movements`. Those go through [StockMovementRepository] — the single
/// writer — so a manual quantity change and its ledger row can never be
/// separated (stock.md §2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/ingredient.dart';

class IngredientRepository {
  final Database _db;

  const IngredientRepository(this._db);

  /// Every non-archived ingredient, alphabetically — powers the admin list.
  Future<List<Ingredient>> all() async {
    final rows = await _db.query(
      'ingredients',
      where: 'is_archived = 0',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Ingredient.fromRow).toList();
  }

  Future<Ingredient?> byId(int id) async {
    final rows = await _db.query(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Ingredient.fromRow(rows.first);
  }

  Future<int> add(Ingredient ingredient) async {
    return _db.insert(
      'ingredients',
      {...ingredient.toRow(), 'created_at': DateTime.now().millisecondsSinceEpoch},
    );
  }

  /// Updates name / reorder threshold / archived flag. The `unit` is NOT
  /// updated here by design — changing it after movements exist is a
  /// data-integrity foot-gun (a "g" ingredient with history reinterpreted as
  /// "unit"). See stock.md §4.1 and [updateAllowed].
  Future<void> update(Ingredient ingredient) async {
    await _db.update(
      'ingredients',
      {
        'name': ingredient.name,
        'reorder_threshold': ingredient.reorderThreshold,
        'is_archived': ingredient.isArchived ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  /// Soft-delete: archived ingredients leave new editing/restock UI, but their
  /// historical product_recipes and stock_movements rows stay for accuracy.
  Future<void> archive(int id) async {
    await _db.update(
      'ingredients',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently removes the ingredient.
  ///
  /// Runs in one transaction and first deletes the rows that reference it
  /// (`product_recipes` bindings and `stock_movements` history), then the
  /// ingredient itself — `ingredient_id` is a foreign key in both, so deleting
  /// the ingredient alone would fail the FK check. Prefer [archive] when the
  /// audit trail matters; use this only to irreversibly drop an item.
  Future<void> delete(int id) async {
    await _db.transaction((txn) async {
      await txn.delete(
        'product_recipes',
        where: 'ingredient_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'stock_movements',
        where: 'ingredient_id = ?',
        whereArgs: [id],
      );
      await txn.delete('ingredients', where: 'id = ?', whereArgs: [id]);
    });
  }
}

final ingredientRepositoryProvider = FutureProvider<IngredientRepository>(
  (ref) async =>
      IngredientRepository(await ref.watch(appDatabaseProvider.future)),
);

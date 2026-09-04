/// Read/write access to `product_recipes` — the mapping from each product to
/// the ingredients it consumes per unit sold.
///
/// [getRecipeForProduct] is the **single** query used both by the recipe
/// editor and by the sale-time deduction logic (stock.md §3.1) — callers must
/// not re-implement it, so the editor and the stock engine can never disagree
/// about what a product consumes.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/recipe_entry.dart';

class RecipeRepository {
  final Database _db;

  const RecipeRepository(this._db);

  /// The recipe for [productId], as a list of (ingredient, quantity-per-unit)
  /// rows. Products with no rows are **untracked** — selling them doesn't
  /// touch stock (stock.md §1.3).
  ///
  /// [txn] lets a caller running inside a transaction hand in the transaction
  /// handle so the read happens on it (never on the outer `_db`) — sqflite
  /// locks the database during a transaction, and querying `_db` from within
  /// one deadlocks (see the stock deduction wiring in
  /// `OrderJournalRepository.addOrder`).
  Future<List<RecipeEntry>> getRecipeForProduct(
    String productId, {
    DatabaseExecutor? txn,
  }) async {
    final rows = await (txn ?? _db).rawQuery(
      'SELECT r.ingredient_id AS ingredient_id, '
      'r.quantity_per_unit AS quantity_per_unit, '
      'i.name AS ingredient_name, i.unit AS ingredient_unit '
      'FROM product_recipes r '
      'JOIN ingredients i ON i.id = r.ingredient_id '
      'WHERE r.product_id = ? '
      'ORDER BY i.name COLLATE NOCASE',
      [productId],
    );
    return [
      for (final row in rows)
        RecipeEntry(
          ingredientId: row['ingredient_id'] as int,
          ingredientName: (row['ingredient_name'] as String?) ?? 'Unknown',
          ingredientUnit: _unitFrom(row['ingredient_unit'] as String?),
          quantityPerUnit: row['quantity_per_unit'] as int,
        ),
    ];
  }

  /// Replaces the whole recipe for [productId] in one transaction (delete all
  /// rows, re-insert). [entries] maps ingredientId → quantity-per-unit.
  Future<void> setRecipe(String productId, List<(int ingredientId, int quantityPerUnit)> entries) async {
    final cleaned = entries
        .where((e) => e.$2 > 0)
        .toSet(); // de-duplicate by ingredient, last wins conceptually
    await _db.transaction((txn) async {
      await txn.delete(
        'product_recipes',
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      for (final (ingredientId, quantity) in cleaned) {
        await txn.insert('product_recipes', {
          'product_id': productId,
          'ingredient_id': ingredientId,
          'quantity_per_unit': quantity,
        });
      }
    });
  }

  static IngredientUnit _unitFrom(String? label) {
    if (label == null) return IngredientUnit.units;
    return IngredientUnit.values.firstWhere(
      (u) => u.label == label,
      orElse: () => IngredientUnit.units,
    );
  }
}

final recipeRepositoryProvider = FutureProvider<RecipeRepository>(
  (ref) async =>
      RecipeRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Product stock sentiment for the admin product table: whether a product's
/// tracked ingredients are low or out, plus how many servings remain.
///
/// Admin-only consumption (stock is a privacy boundary — waiters never see
/// stock levels). Follows stock.md §3.2 *warn, don't block*: a low/out product
/// is still tappable and sellable; the product table just flags it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/models/ingredient_format.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/core/repositories/recipe_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';

/// The stock sentiment of a menu product for badge display.
enum ProductStockStatus { ok, low, out }

/// What the product table needs to know about a product's stock in one object.
class ProductStockInfo {
  final ProductStockStatus status;

  /// How many servings can still be made, limited by the most-limiting tracked
  /// ingredient (floored). Large sentinel when the product is untracked.
  final int servingsLeft;

  const ProductStockInfo({required this.status, required this.servingsLeft});

  // Sentinels for untracked products (no recipe) — always ok, effectively
  // unbounded servings.
  static const ProductStockInfo unlimited = ProductStockInfo(
    status: ProductStockStatus.ok,
    servingsLeft: 0x7fffffff,
  );
}

/// Stock sentiment + remaining servings for every menu product.
///
/// A product with **no** recipe rows is "untracked" and always `ok`/unlimited
/// (selling it doesn't touch stock). Otherwise status is `out` if any tracked
/// ingredient is out, `low` if any is low, else `ok`; `servingsLeft` is the
/// minimum across tracked ingredients (the binding limit). Re-computed whenever
/// stock or the catalog changes (both watched below).
final productStockProvider =
    FutureProvider<Map<String, ProductStockInfo>>((ref) async {
  ref.watch(ingredientMutationProvider);
  final products = await ref.watch(menuProductsProvider.future);
  final ingredients = await ref.watch(allIngredientsProvider.future);
  final stockById = {
    for (final i in ingredients) i.id: i,
  };
  final recipeRepo = await ref.watch(recipeRepositoryProvider.future);

  final result = <String, ProductStockInfo>{};
  for (final Product product in products) {
    final recipe = await recipeRepo.getRecipeForProduct(product.id);
    if (recipe.isEmpty) {
      result[product.id] = ProductStockInfo.unlimited;
      continue;
    }

    var status = ProductStockStatus.ok;
    var servingsLeft = 0x7fffffff;
    for (final entry in recipe) {
      final ingredient = stockById[entry.ingredientId];
      if (ingredient == null) continue;

      // Tracked ingredient: contributes its own status + serving count.
      final ingredientStatus = ingredient.isOutOfStock
          ? ProductStockStatus.out
          : ingredient.isLowStock
              ? ProductStockStatus.low
              : ProductStockStatus.ok;
      final ingredientServings = servingsFrom(
        ingredient.currentStock,
        entry.quantityPerUnit,
      );
      if (ingredientServings < servingsLeft) {
        servingsLeft = ingredientServings;
      }
      if (ingredientStatus == ProductStockStatus.out) {
        status = ProductStockStatus.out;
      } else if (ingredientStatus == ProductStockStatus.low &&
          status == ProductStockStatus.ok) {
        status = ProductStockStatus.low;
      }
    }

    // If everything looks fine, still cap the display so "ok" doesn't get an
    // unbounded number fed to a badge (it won't be shown for ok anyway).
    result[product.id] = ProductStockInfo(
      status: status,
      servingsLeft: servingsLeft,
    );
  }
  return result;
});

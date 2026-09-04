/// Admin-facing derivation of "how many servings are left" per ingredient.
///
/// Turns a raw on-hand stock number into something operators act on: "about
/// 80 cups left". Each ingredient may feed several products at different
/// quantities-per-serving, so we use the **binding (largest) per-serving amount**
/// across every product's recipe — the most conservative, honest estimate of
/// how many servings the on-hand stock can produce.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/models/ingredient_format.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/core/repositories/recipe_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';

/// ingredientId → servings that can still be made from current on-hand stock.
///
/// Only ingredients bound to at least one product appear. Re-computed whenever
/// stock or the catalog changes (both watched below).
final ingredientServingsProvider =
    FutureProvider<Map<int, int>>((ref) async {
  ref.watch(ingredientMutationProvider);
  final ingredients = await ref.watch(allIngredientsProvider.future);
  final products = await ref.watch(menuProductsProvider.future);
  final stockById = {for (final i in ingredients) i.id: i};
  final recipeRepo = await ref.watch(recipeRepositoryProvider.future);

  // Accumulate the largest quantity-per-serving each ingredient is used at.
  final maxPerServing = <int, int>{};
  for (final product in products) {
    final recipe = await recipeRepo.getRecipeForProduct(product.id);
    for (final entry in recipe) {
      final current = maxPerServing[entry.ingredientId] ?? 0;
      if (entry.quantityPerUnit > current) {
        maxPerServing[entry.ingredientId] = entry.quantityPerUnit;
      }
    }
  }

  final result = <int, int>{};
  for (final entry in maxPerServing.entries) {
    final ingredient = stockById[entry.key];
    if (ingredient == null) continue;
    result[entry.key] = servingsFrom(
      ingredient.currentStock,
      entry.value,
    );
  }
  return result;
});

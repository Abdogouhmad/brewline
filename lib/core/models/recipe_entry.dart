import 'ingredient.dart';

/// One row of a product's recipe: how much of an [ingredient] is consumed per
/// **one unit** of the product sold.
///
/// Consumed quantities are derived at sale/refund time as
/// `quantityPerUnit × itemQuantity`. A product with no recipe rows inside
/// `product_recipes` is treated as **untracked** — selling it doesn't touch
/// stock at all (stock.md §1.3).
class RecipeEntry {
  final int ingredientId;
  final String ingredientName;
  final IngredientUnit ingredientUnit;

  /// Consumed per 1 unit of the product sold (always > 0).
  final int quantityPerUnit;

  const RecipeEntry({
    required this.ingredientId,
    required this.ingredientName,
    required this.ingredientUnit,
    required this.quantityPerUnit,
  });
}

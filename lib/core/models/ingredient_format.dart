/// Display helpers for ingredient quantities and derived servings.
///
/// Quantities are stored as integers in the ingredient's smallest unit
/// (grams / ml / whole units — see stock.md §1.2); these helpers only make
/// them readable (g → kg, ml → L) and translate on-hand stock into a
/// meaningful "~N servings left" number. They never mutate stored values.
library;

import 'ingredient.dart';

/// Human-readable quantity, using a larger unit when it reads better.
///
/// ```dart
/// formatStockQuantity(12500, IngredientUnit.grams) // '12.5 kg'
/// formatStockQuantity(36,    IngredientUnit.grams) // '36 g'
/// formatStockQuantity(8,     IngredientUnit.units) // '8'
/// ```
String formatStockQuantity(int amount, IngredientUnit unit) {
  switch (unit) {
    case IngredientUnit.grams:
      if (amount.abs() >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)} kg';
      }
      return '$amount g';
    case IngredientUnit.millilitres:
      if (amount.abs() >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)} L';
      }
      return '$amount ml';
    case IngredientUnit.units:
      return '$amount';
  }
}

/// Whole servings that can be made from [stock] when each one consumes
/// [perServing]. Never negative; `0` when stock is empty/negative or the per
/// serving quantity is unset.
int servingsFrom(int stock, int perServing) {
  if (perServing <= 0 || stock <= 0) return 0;
  return stock ~/ perServing;
}

/// A friendly "you bought X → about N servings" hint for the recipe editor,
/// e.g. `1.0 kg → about 83 cups` for 12 g per cup.
///
/// [servingWord] is the noun the admin uses for one unit sold (e.g. 'cup',
/// 'bottle', 'unit'); the bulk amount come from the in-progress stocking flow
/// and is a *guide*, not a stored value.
String bulkYieldHint({
  required int bulkAmount,
  required int perServing,
  required IngredientUnit unit,
  required String servingWord,
}) {
  if (perServing <= 0 || bulkAmount <= 0) return '';
  final servings = servingsFrom(bulkAmount, perServing);
  return '${formatStockQuantity(bulkAmount, unit)} → about '
      '$servings $servingWord${servings == 1 ? '' : 's'}';
}

/// Whether an ingredient has a friendlier *large* scale to enter/display bulk
/// quantities in (kg for weight, L for volume). Whole-unit ingredients (cups,
/// lids, cans) don't — they're already in the natural unit.
bool hasLargeScale(IngredientUnit unit) =>
    unit == IngredientUnit.grams || unit == IngredientUnit.millilitres;

/// Label of the *large* scale for [unit], e.g. 'kg' for grams, 'L' for ml.
String largeScaleLabel(IngredientUnit unit) => switch (unit) {
  IngredientUnit.grams => 'kg',
  IngredientUnit.millilitres => 'L',
  IngredientUnit.units => 'unit',
};

/// Converts a user-entered [value] (which may be fractional in the large
/// scale, e.g. `1.5` kg) into the integer **base-unit** quantity stored on the
/// ingredient (grams / ml / whole units). [large] selects kg/L vs base.
///
/// ```dart
/// toBaseQuantity(1.5, IngredientUnit.grams, large: true)  // 1500
/// toBaseQuantity(12,   IngredientUnit.grams, large: false) // 12
/// toBaseQuantity(1.5,  IngredientUnit.millilitres, large: true) // 1500
/// toBaseQuantity(8,    IngredientUnit.units, large: false) // 8
/// ```
int toBaseQuantity({
  required double value,
  required IngredientUnit unit,
  required bool large,
}) {
  if (hasLargeScale(unit) && large) {
    return (value * 1000).round();
  }
  return value.round();
}


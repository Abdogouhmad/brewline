/// Unit of measure for an [Ingredient]'s stock quantity.
///
/// Quantities are always stored as **integers in the smallest sensible unit**
/// (grams for weight, millilitres for volume, whole units for discrete items
/// like cups/lids/cans) — the same "no floating-point drift" reasoning used
/// for money-in-cents. The UI converts to a display-friendly form (e.g.
/// grams → kg) only when rendering.
enum IngredientUnit {
  grams('g'),
  millilitres('ml'),
  units('unit');

  /// The storage/display symbol for the unit.
  final String label;

  const IngredientUnit(this.label);
}

/// One raw stock item — coffee beans, milk, syrup, cups, lids, etc.
///
/// `currentStock` is a **live** value read on every sale before a waiter
/// completes an order; it may go negative (stock data can lag reality and a
/// sale should still complete — see stock.md §3.2). The audit trail that
/// explains how it got there lives in `stock_movements`.
class Ingredient {
  final int id;

  final String name;

  /// The unit this stock is tracked in (grams / ml / whole units).
  final IngredientUnit unit;

  /// Live quantity on hand, in [unit]'s smallest denomination. May be
  /// negative; that's information, not an error (stock.md §3.2).
  final int currentStock;

  /// At or below this value the low-stock indicator triggers.
  final int reorderThreshold;

  /// Soft-delete flag; archived ingredients leave new editing/restock UI but
  /// their historical recipe rows and movements stay intact.
  final bool isArchived;

  const Ingredient({
    this.id = 0,
    required this.name,
    required this.unit,
    this.currentStock = 0,
    this.reorderThreshold = 0,
    this.isArchived = false,
  });

  /// True when this tracked ingredient is at/below its restock threshold.
  bool get isLowStock =>
      !isArchived && currentStock <= reorderThreshold;

  /// True when there is genuinely none left (useful for an "out" badge).
  bool get isOutOfStock => currentStock <= 0;

  Map<String, Object?> toRow() => {
    'name': name,
    'unit': unit.label,
    'current_stock': currentStock,
    'reorder_threshold': reorderThreshold,
    'is_archived': isArchived ? 1 : 0,
  };

  static Ingredient fromRow(Map<String, Object?> row) => Ingredient(
    id: row['id'] as int,
    name: row['name'] as String,
    unit: _unitFromLabel(row['unit'] as String),
    currentStock: row['current_stock'] as int? ?? 0,
    reorderThreshold: row['reorder_threshold'] as int? ?? 0,
    isArchived: (row['is_archived'] as int? ?? 0) == 1,
  );

  static IngredientUnit _unitFromLabel(String label) =>
      IngredientUnit.values.firstWhere(
        (u) => u.label == label,
        orElse: () => IngredientUnit.units,
      );

  Ingredient copyWith({
    int? id,
    String? name,
    IngredientUnit? unit,
    int? currentStock,
    int? reorderThreshold,
    bool? isArchived,
  }) => Ingredient(
    id: id ?? this.id,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    currentStock: currentStock ?? this.currentStock,
    reorderThreshold: reorderThreshold ?? this.reorderThreshold,
    isArchived: isArchived ?? this.isArchived,
  );
}

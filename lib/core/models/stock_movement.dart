import 'ingredient.dart';

/// Why a stock quantity changed. Every movement row carries exactly one of
/// these — there is no "unknown" reason, so the ledger is always explainable.
enum StockMovementReason {
  /// Consumed by a sale (negative change).
  sale('sale'),

  /// Added back by a refund / order void (positive change).
  refundRestock('refund_restock'),

  /// Manual restock from a supplier (positive change).
  restock('restock'),

  /// Stock-count correction (can be positive or negative).
  manualAdjustment('manual_adjustment'),

  /// Wasted / broken / spilled (negative change).
  waste('waste');

  /// Storage value for the `stock_movements.reason` column.
  final String label;

  const StockMovementReason(this.label);

  static StockMovementReason fromLabel(String label) =>
      StockMovementReason.values.firstWhere(
        (r) => r.label == label,
        orElse: () => StockMovementReason.manualAdjustment,
      );
}

/// One immutable row of the `stock_movements` ledger — an explainable,
/// auditable quantity change for a single ingredient.
///
/// `changeAmount` is negative when stock was consumed and positive when added
/// back. This table is the source of truth that explains `current_stock`; both
/// are always written together in the same transaction (stock.md §1.2).
class StockMovement {
  final int id;
  final int ingredientId;
  final String ingredientName;
  final IngredientUnit ingredientUnit;
  final int changeAmount;
  final StockMovementReason reason;

  /// Set when [reason] is [StockMovementReason.sale] or
  /// [StockMovementReason.refundRestock].
  final int? orderId;

  /// The admin account id for manual actions (restock, adjustment, waste).
  final String? adminId;

  final String? note;
  final DateTime createdAt;

  const StockMovement({
    this.id = 0,
    required this.ingredientId,
    this.ingredientName = '',
    this.ingredientUnit = IngredientUnit.units,
    required this.changeAmount,
    required this.reason,
    this.orderId,
    this.adminId,
    this.note,
    required this.createdAt,
  });
}

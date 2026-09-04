/// **The only writer of `ingredients.current_stock` and `stock_movements`** in
/// the entire codebase. Any other repository mutating either table directly is
/// a bug, not a shortcut — this single choke point guarantees the live
/// quantity and its audit ledger can never drift out of sync.
///
/// ## Why both writes are always atomic
/// `current_stock` is read on **every** sale, so it's a live, incrementally
/// updated number; `stock_movements` is the append-only ledger that explains
/// it. Keeping them in one place (and, for consumer callers, one transaction)
/// means a crash between "ledger wrote" and "quantity updated" is impossible
/// — the two can never disagree. This mirrors the `cashout_logs` snapshot +
/// `audit_events` split used elsewhere: a fast live value plus an explainable
/// history (stock.md §1.2).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/stock_movement.dart';

/// Filter set for [StockMovementRepository.getMovements].
class StockMovementFilter {
  final DateTime? from;
  final DateTime? to;
  final int? ingredientId;
  final StockMovementReason? reason;

  const StockMovementFilter({this.from, this.to, this.ingredientId, this.reason});
}

class IngredientMutationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final ingredientMutationProvider =
    NotifierProvider<IngredientMutationNotifier, int>(
      IngredientMutationNotifier.new,
    );

/// Writes to `stock_movements` / `ingredients.current_stock`. Construct once
/// via [stockMovementRepositoryProvider].
class StockMovementRepository {
  final Database _db;

  const StockMovementRepository(this._db);

  /// Records one movement and updates the ingredient's live quantity in a
  /// single transaction.
  ///
  /// [changeAmount] is negative when consumed, positive when added back.
  /// [createdAt] is injected (defaults to now) so sale-time loggers can share
  /// one timestamp across the order + movements rows.
  Future<void> logMovement({
    required DatabaseExecutor txn,
    required int ingredientId,
    required int changeAmount,
    required StockMovementReason reason,
    int? orderId,
    String? adminId,
    String? note,
    DateTime? createdAt,
  }) async {
    final at = createdAt ?? DateTime.now();
    await txn.insert('stock_movements', {
      'ingredient_id': ingredientId,
      'change_amount': changeAmount,
      'reason': reason.label,
      'order_id': orderId,
      'admin_id': adminId,
      'note': note,
      'created_at': at.millisecondsSinceEpoch,
    });
    await txn.rawUpdate(
      'UPDATE ingredients SET current_stock = current_stock + ? WHERE id = ?',
      [changeAmount, ingredientId],
    );
  }

  /// Same as [logMovement] but opens its own transaction — for standalone
  /// admin actions (restock, waste, adjustment) that aren't part of an order.
  Future<void> logStandalone({
    required int ingredientId,
    required int changeAmount,
    required StockMovementReason reason,
    String? adminId,
    String? note,
  }) async {
    await _db.transaction(
      (txn) => logMovement(
        txn: txn,
        ingredientId: ingredientId,
        changeAmount: changeAmount,
        reason: reason,
        adminId: adminId,
        note: note,
      ),
    );
  }

  /// The movements ledger, most recent first. Joins `ingredients` so results
  /// carry the ingredient name/unit for display without a second lookup.
  Future<List<StockMovement>> getMovements(StockMovementFilter filter) async {
    final where = <String>[];
    final args = <Object?>[];
    if (filter.from != null) {
      where.add('m.created_at >= ?');
      args.add(filter.from!.millisecondsSinceEpoch);
    }
    if (filter.to != null) {
      where.add('m.created_at < ?');
      args.add(filter.to!.millisecondsSinceEpoch);
    }
    if (filter.ingredientId != null) {
      where.add('m.ingredient_id = ?');
      args.add(filter.ingredientId);
    }
    if (filter.reason != null) {
      where.add('m.reason = ?');
      args.add(filter.reason!.label);
    }

    final rows = await _db.rawQuery(
      'SELECT m.*, i.name AS ingredient_name, i.unit AS ingredient_unit '
      'FROM stock_movements m '
      'LEFT JOIN ingredients i ON i.id = m.ingredient_id '
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} '
      'ORDER BY m.id DESC',
      args,
    );
    return [
      for (final row in rows)
        StockMovement(
          id: row['id'] as int,
          ingredientId: row['ingredient_id'] as int,
          ingredientName: (row['ingredient_name'] as String?) ?? 'Deleted ingredient',
          ingredientUnit: _unitFrom(row['ingredient_unit'] as String?),
          changeAmount: row['change_amount'] as int,
          reason: StockMovementReason.fromLabel(row['reason'] as String),
          orderId: row['order_id'] as int?,
          adminId: row['admin_id'] as String?,
          note: row['note'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int,
          ),
        ),
    ];
  }

  /// Total count of movements for an ingredient — used to lock its unit field
  /// once it has any history (stock.md §4.1).
  Future<int> movementCountForIngredient(int ingredientId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM stock_movements WHERE ingredient_id = ?',
      [ingredientId],
    );
    return (rows.first['c'] as num).toInt();
  }

  static IngredientUnit _unitFrom(String? label) {
    if (label == null) return IngredientUnit.units;
    return IngredientUnit.values.firstWhere(
      (u) => u.label == label,
      orElse: () => IngredientUnit.units,
    );
  }
}

final stockMovementRepositoryProvider = FutureProvider<StockMovementRepository>(
  (ref) async =>
      StockMovementRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Every non-archived ingredient, plus a live low-stock provider — recompute
/// on any write through [ingredientMutationProvider].
final allIngredientsProvider = FutureProvider<List<Ingredient>>((ref) async {
  ref.watch(ingredientMutationProvider);
  final rows = await (await ref.watch(appDatabaseProvider.future))
      .query('ingredients', where: 'is_archived = 0', orderBy: 'name COLLATE NOCASE');
  return rows.map(Ingredient.fromRow).toList();
});

/// Ingredients at/below their reorder threshold — powers the dashboard card and
/// the inventory nav badge.
final lowStockIngredientsProvider = FutureProvider<List<Ingredient>>((ref) async {
  ref.watch(ingredientMutationProvider);
  final db = await ref.watch(appDatabaseProvider.future);
  final rows = await db.query(
    'ingredients',
    where: 'is_archived = 0 AND current_stock <= reorder_threshold',
    orderBy: 'current_stock ASC',
  );
  return rows.map(Ingredient.fromRow).toList();
});

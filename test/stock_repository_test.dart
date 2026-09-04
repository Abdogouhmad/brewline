import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/order_item_adjustment.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/models/stock_movement.dart';
import 'package:brewline/core/repositories/ingredient_repository.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/core/repositories/recipe_repository.dart';
import 'package:brewline/core/repositories/refund_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Verifies the ingredient-level stock flow (stock.md):
/// 1. `current_stock` and the `stock_movements` ledger are written together
///    (the single-writer `StockMovementRepository`).
/// 2. A sale deducts exactly the recipe-derived quantity, in the same
///    transaction as the order batch (untracked products are skipped).
/// 3. A partial refund restores just the removed units; a full void restores
///    the whole order.
void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  late Database db;
  late IngredientRepository ingredients;
  late RecipeRepository recipes;
  late StockMovementRepository movements;
  late OrderJournalRepository journal;
  late RefundRepository refunds;
  late DateTime now;

  Future<void> seedBeansAndCups() async {
    final beansId = await ingredients.add(
      Ingredient(
        name: 'Coffee beans',
        unit: IngredientUnit.grams,
        currentStock: 2000,
        reorderThreshold: 400,
      ),
    );
    final milkId = await ingredients.add(
      Ingredient(name: 'Milk', unit: IngredientUnit.millilitres, currentStock: 0),
    );
    final cupsId = await ingredients.add(
      Ingredient(name: 'Cups', unit: IngredientUnit.units, currentStock: 100),
    );
    await recipes.setRecipe('p-001', [
      (beansId, 18),
      (cupsId, 1),
    ]);
    await recipes.setRecipe('p-002', [(milkId, 250)]);
    return;
  }

  setUp(() async {
    sqfliteFfiInit();
    db = await inMemoryDb();
    await seedDefaultProducts(db); // provides p-001 (Espresso), p-002
    ingredients = IngredientRepository(db);
    recipes = RecipeRepository(db);
    movements = StockMovementRepository(db);
    journal = OrderJournalRepository(db);
    refunds = RefundRepository(db);
    now = DateTime.now();
    await seedBeansAndCups();
  });

  tearDown(() => db.close());

  Future<Ingredient> ing(String name) async {
    final list = await ingredients.all();
    return list.singleWhere((i) => i.name == name);
  }

  test('sale deducts recipe-derived quantity and logs a sale movement',
      () async {
    await journal.addOrder(
      OrderRecord(
        id: 1,
        createdAt: now,
        waiterUsername: 'waiter1',
        total: 18,
        items: const [
          // 2 × Espresso → 36 g beans, 2 cups
          OrderLineItem(
            productId: 'p-001',
            name: 'Espresso',
            quantity: 2,
            unitPrice: 9,
          ),
        ],
      ),
    );

    final beans = await ing('Coffee beans');
    expect(beans.currentStock, 2000 - 36); // 1964
    final cups = await ing('Cups');
    expect(cups.currentStock, 100 - 2); // 98

    // Ledger has exactly one 'sale' movement for each consumed ingredient.
    final log = await movements.getMovements(const StockMovementFilter());
    expect(log, hasLength(2));
    final beansMove = log.singleWhere((m) => m.ingredientName == 'Coffee beans');
    expect(beansMove.changeAmount, -36);
    expect(beansMove.reason, StockMovementReason.sale);
    expect(beansMove.orderId, 1);
  });

  test('untracked product does not touch stock', () async {
    // p-005 (Water) exists in the catalog but has no recipe rows → untracked.

    await journal.addOrder(
      OrderRecord(
        id: 1,
        createdAt: now,
        waiterUsername: 'waiter1',
        total: 5,
        items: const [
          OrderLineItem(
            productId: 'p-005',
            name: 'Water',
            quantity: 3,
            unitPrice: 5,
          ),
        ],
      ),
    );

    final log = await movements.getMovements(const StockMovementFilter());
    expect(log, isEmpty);
  });

  test('partial refund restores only the removed units', () async {
    await journal.addOrder(
      OrderRecord(
        id: 1,
        createdAt: now,
        waiterUsername: 'w',
        total: 18,
        items: const [
          OrderLineItem(
            productId: 'p-001',
            name: 'Espresso',
            quantity: 2,
            unitPrice: 9,
          ),
        ],
      ),
    );
    expect((await ing('Coffee beans')).currentStock, 2000 - 36);

    final order = await refunds.getOrder(1);
    final line = order!.items.single;

    // Refund 1 of the 2 Espressos → restore 18 g beans + 1 cup.
    await refunds.applyPartialRefund(
      orderId: 1,
      adminId: 'admin',
      reason: 'one too many',
      adjustments: [
        OrderItemAdjustment(
          orderItemId: line.id,
          originalQuantity: 2,
          unitPrice: 9,
          newQuantity: 1,
        ),
      ],
    );

    expect((await ing('Coffee beans')).currentStock, 2000 - 18);
    expect((await ing('Cups')).currentStock, 100 - 1);

    final log = await movements.getMovements(const StockMovementFilter());
    final beansRestock = log.singleWhere(
      (m) =>
          m.reason == StockMovementReason.refundRestock &&
          m.ingredientName == 'Coffee beans',
    );
    expect(beansRestock.changeAmount, 18);
    expect(beansRestock.orderId, 1);
  });

  test('full void restores the entire order', () async {
    await journal.addOrder(
      OrderRecord(
        id: 1,
        createdAt: now,
        waiterUsername: 'w',
        total: 18,
        items: const [
          OrderLineItem(
            productId: 'p-001',
            name: 'Espresso',
            quantity: 2,
            unitPrice: 9,
          ),
        ],
      ),
    );
    expect((await ing('Coffee beans')).currentStock, 2000 - 36);

    await refunds.voidOrder(orderId: 1, adminId: 'admin', reason: 'void');

    // Beans back to full.
    expect((await ing('Coffee beans')).currentStock, 2000);
    final log = await movements.getMovements(const StockMovementFilter());
    expect(
      log.where((m) => m.reason == StockMovementReason.refundRestock),
      hasLength(2),
    );
  });
}

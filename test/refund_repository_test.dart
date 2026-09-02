import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/order_item_adjustment.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/core/repositories/refund_repository.dart';
import 'package:brewline/core/repositories/sales_query_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  group('refund repository', () {
    late Database db;
    late OrderJournalRepository journal;
    late RefundRepository refunds;
    late AuditRepository audit;
    late SalesQueryRepository sales;
    late DateTime now;

    // Order 1: 2×9 Espresso + 1×6 Cola = 24. Order 2: 1×15 Cola = 15.
    Future<void> seedOrders() async {
      await journal.addOrder(
        OrderRecord(
          id: 1,
          createdAt: now,
          waiterUsername: 'waiter1',
          total: 24,
          items: const [
            OrderLineItem(productId: 'coffee-1', name: 'Espresso', quantity: 2, unitPrice: 9),
            OrderLineItem(productId: 'drink-1', name: 'Cola', quantity: 1, unitPrice: 6),
          ],
        ),
      );
      await journal.addOrder(
        OrderRecord(
          id: 2,
          createdAt: now,
          waiterUsername: 'waiter1',
          total: 15,
          items: const [
            OrderLineItem(productId: 'drink-1', name: 'Cola', quantity: 1, unitPrice: 15),
          ],
        ),
      );
    }

    setUp(() async {
      db = await inMemoryDb();
      await deleteAllData(db);
      journal = OrderJournalRepository(db);
      refunds = RefundRepository(db);
      audit = AuditRepository(db);
      sales = SalesQueryRepository(db);
      now = DateTime.now();
      await seedOrders();
    });

    tearDown(() => db.close());

    test('partial refund reduces a line and nets the dashboard total', () async {
      final order = await refunds.getOrder(1);
      final espressoLine = order!.items.singleWhere(
        (i) => i.productId == 'coffee-1',
      );

      // Remove the whole 2× Espresso line (24 worth of coffee) → refund 18.
      final result = await refunds.applyPartialRefund(
        orderId: 1,
        adminId: 'admin',
        reason: 'wrong item entered',
        adjustments: [
          OrderItemAdjustment(
            orderItemId: espressoLine.id,
            originalQuantity: 2,
            unitPrice: 9,
            newQuantity: 0,
          ),
        ],
      );

      expect(result.amountCents, 1800);
      expect(result.isFull, isFalse);

      // The order's line items are corrected; only the 6 Cola remains.
      final updated = await refunds.getOrder(1);
      expect(updated!.items, hasLength(1));
      expect(updated.items.singleWhere((i) => i.productId == 'drink-1').quantity, 1);
      // orders.total keeps the original charged amount (the net is derived
      // as total − refund), so the refund amount isn't double-subtracted.
      expect(updated.total, closeTo(24, 0.001));

      // One partial refund row logged.
      final refundsLogged = await refunds.getRefundsForOrder(1);
      expect(refundsLogged, hasLength(1));
      final r = refundsLogged.single;
      expect(r.refundType, 'partial');
      expect(r.amountCents, 1800);
      expect(r.reason, 'wrong item entered');

      // post_print_edit audit signal written.
      final events = await audit.recent();
      expect(events.any((e) => e.eventType == 'post_print_edit'), isTrue);

      // Net dashboard revenue reflects the correction.
      final stats = await journal.statsBetween(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      expect(stats.revenue, closeTo(21, 0.001)); // 24+15 - 18 refund
      expect(stats.orderCount, 2);
    });

    test('void order flags is_voided, keeps items, and logs void signal',
        () async {
      final result = await refunds.voidOrder(
        orderId: 1,
        adminId: 'admin',
        reason: 'customer left',
      );

      expect(result.amountCents, 2400);
      expect(result.isFull, isTrue);

      // Order flagged voided but its items are untouched.
      final order = await refunds.getOrder(1);
      expect(order!.isVoided, isTrue);
      expect(order.items, hasLength(2));
      expect(order.total, closeTo(24, 0.001));

      // Full refund row logged.
      final refundsLogged = await refunds.getRefundsForOrder(1);
      expect(refundsLogged.single.refundType, 'full');
      expect(refundsLogged.single.amountCents, 2400);

      // void audit signal written.
      final events = await audit.recent();
      expect(events.any((e) => e.eventType == 'void'), isTrue);

      // Voided order no longer counts toward sales or the heatmap.
      final stats = await journal.statsBetween(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      expect(stats.revenue, closeTo(15, 0.001)); // only order 2 survives
      expect(stats.orderCount, 1);

      final heat = await sales.ordersByWeekdayHour(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      final totalCells = heat.fold<int>(0, (s, c) => s + c.orders);
      expect(totalCells, 1); // only order 2 counted
    });

    test('voided and partially refunded rows carry badges in the Sales Log',
        () async {
      await refunds.voidOrder(orderId: 2, adminId: 'admin', reason: 'void');
      final order = await refunds.getOrder(1);
      final espressoLine = order!.items.singleWhere(
        (i) => i.productId == 'coffee-1',
      );
      await refunds.applyPartialRefund(
        orderId: 1,
        adminId: 'admin',
        reason: 'corrected',
        adjustments: [
          OrderItemAdjustment(
            orderItemId: espressoLine.id,
            originalQuantity: 2,
            unitPrice: 9,
            newQuantity: 1,
          ),
        ],
      );

      final rows = await sales.getSales();
      // Order 1 (partial) line + Order 2 (voided) line.
      expect(rows.where((r) => r.orderId == 1).every(
        (r) => r.refundState == SalesRefundState.partial,
      ), isTrue);
      final voidedRow = rows.singleWhere((r) => r.orderId == 2);
      expect(voidedRow.refundState, SalesRefundState.voided);
      expect(voidedRow.netTotal, 0);
    });

    test('partial refund refuses to increase a quantity (decrease-only)',
        () async {
      final order = await refunds.getOrder(1);
      final line = order!.items.first;

      expect(
        () => refunds.applyPartialRefund(
          orderId: 1,
          adminId: 'admin',
          reason: 'nope',
          adjustments: [
            OrderItemAdjustment(
              orderItemId: line.id,
              originalQuantity: 2,
              unitPrice: 9,
              newQuantity: 3,
            ),
          ],
        ),
        throwsStateError,
      );
    });

    test('getRefundsForOrder returns multiple partials oldest first', () async {
      final order = await refunds.getOrder(1);
      final espresso = order!.items.singleWhere(
        (i) => i.productId == 'coffee-1',
      );
      final cola = order.items.singleWhere((i) => i.productId == 'drink-1');

      await refunds.applyPartialRefund(
        orderId: 1,
        adminId: 'admin',
        reason: 'first',
        adjustments: [
          OrderItemAdjustment(
            orderItemId: espresso.id,
            originalQuantity: 2,
            unitPrice: 9,
            newQuantity: 1,
          ),
        ],
      );
      await refunds.applyPartialRefund(
        orderId: 1,
        adminId: 'admin',
        reason: 'second',
        adjustments: [
          OrderItemAdjustment(
            orderItemId: cola.id,
            originalQuantity: 1,
            unitPrice: 6,
            newQuantity: 0,
          ),
        ],
      );

      final history = await refunds.getRefundsForOrder(1);
      expect(history, hasLength(2));
      expect(history[0].reason, 'first');
      expect(history[1].reason, 'second');
    });
  });
}

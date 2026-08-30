import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  group('order journal aggregates', () {
    late Database db;
    late OrderJournalRepository journal;
    late ProductRepository products;
    late DateTime now;

    setUp(() async {
      db = await inMemoryDb();
      await deleteAllData(db);
      journal = OrderJournalRepository(db);
      products = ProductRepository(db);

      await products.upsert(
        const Product(
          id: 'coffee-1',
          name: 'Espresso',
          price: 9,
          imagePath: '',
          category: 'Coffee',
        ),
      );
      await products.upsert(
        const Product(
          id: 'drink-1',
          name: 'Cola',
          price: 15,
          imagePath: '',
          category: 'Soft drinks',
        ),
      );

      now = DateTime.now();
    });

    OrderRecord order({
      required int id,
      required double total,
      DateTime? at,
      String? waiter,
      List<OrderLineItem> items = const [],
    }) => OrderRecord(
      id: id,
      createdAt: at ?? now,
      waiterUsername: waiter,
      total: total,
      items: items,
    );

    test('statsBetween sums revenue, orders and items in a window', () async {
      await journal.addOrder(
        order(
          id: 1,
          total: 24,
          waiter: 'waiter1',
          items: const [
            OrderLineItem(
              productId: 'coffee-1',
              name: 'Espresso',
              quantity: 2,
              unitPrice: 9,
            ),
            OrderLineItem(
              productId: 'drink-1',
              name: 'Cola',
              quantity: 1,
              unitPrice: 6,
            ),
          ],
        ),
      );
      await journal.addOrder(
        order(
          id: 2,
          total: 15,
          waiter: 'waiter2',
          items: const [
            OrderLineItem(
              productId: 'drink-1',
              name: 'Cola',
              quantity: 1,
              unitPrice: 15,
            ),
          ],
        ),
      );

      final stats = await journal.statsBetween(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      expect(stats.revenue, closeTo(39, 0.001));
      expect(stats.orderCount, 2);
      expect(stats.itemCount, 4);

      final before = await journal.statsBetween(
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(minutes: 1)),
      );
      expect(before.revenue, 0);
      expect(before.orderCount, 0);
    });

    test(
      'nextOrderId continues from the highest ticket, not a counter',
      () async {
        expect(await journal.nextOrderId(), 1);
        await journal.addOrder(order(id: 1, total: 10));
        await journal.addOrder(order(id: 5, total: 20));
        expect(await journal.nextOrderId(), 6);
      },
    );

    test('topProducts ranks by units sold', () async {
      await journal.addOrder(
        order(
          id: 1,
          total: 24,
          items: const [
            OrderLineItem(
              productId: 'coffee-1',
              name: 'Espresso',
              quantity: 3,
              unitPrice: 9,
            ),
            OrderLineItem(
              productId: 'drink-1',
              name: 'Cola',
              quantity: 1,
              unitPrice: 15,
            ),
          ],
        ),
      );
      await journal.addOrder(
        order(
          id: 2,
          total: 15,
          items: const [
            OrderLineItem(
              productId: 'drink-1',
              name: 'Cola',
              quantity: 1,
              unitPrice: 15,
            ),
          ],
        ),
      );

      final top = await journal.topProducts(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      expect(top.first.productId, 'coffee-1');
      expect(top.first.quantity, 3);
      expect(top.first.name, 'Espresso');
    });

    test('revenueByHour buckets orderCount by local hour', () async {
      await journal.addOrder(order(id: 1, total: 10, at: now));
      await journal.addOrder(order(id: 2, total: 20, at: now));

      final buckets = await journal.revenueByHour(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      final slot = buckets.singleWhere((b) => b.hour == now.hour);
      expect(slot.orderCount, 2);
      expect(slot.revenue, closeTo(30, 0.001));
    });

    test('salesByWaiter credits each waiter from the journal header', () async {
      await journal.addOrder(order(id: 1, total: 30, waiter: 'waiter1'));
      await journal.addOrder(order(id: 2, total: 15, waiter: 'waiter1'));
      await journal.addOrder(order(id: 3, total: 60, waiter: 'waiter2'));

      final sales = await journal.salesByWaiter(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      expect(sales, hasLength(2));
      expect(sales.first.username, 'waiter2');
      expect(sales.first.revenue, closeTo(60, 0.001));
      final second = sales.singleWhere((s) => s.username == 'waiter1');
      expect(second.orderCount, 2);
      expect(second.revenue, closeTo(45, 0.001));
    });

    test(
      'revenueByCategory groups by catalog category, "Other" when missing',
      () async {
        await journal.addOrder(
          order(
            id: 1,
            total: 18,
            items: const [
              OrderLineItem(
                productId: 'coffee-1',
                name: 'Espresso',
                quantity: 2,
                unitPrice: 9,
              ),
            ],
          ),
        );
        await journal.addOrder(
          order(
            id: 2,
            total: 15,
            items: const [
              OrderLineItem(
                productId: 'drink-1',
                name: 'Cola',
                quantity: 1,
                unitPrice: 15,
              ),
            ],
          ),
        );
        await journal.addOrder(
          order(
            id: 3,
            total: 5,
            items: const [
              OrderLineItem(
                productId: 'gone-1',
                name: 'Deleted snack',
                quantity: 1,
                unitPrice: 5,
              ),
            ],
          ),
        );

        final mix = await journal.revenueByCategory(
          now.subtract(const Duration(hours: 1)),
          now.add(const Duration(hours: 1)),
        );
        final coffee = mix.singleWhere((c) => c.category == 'Coffee');
        expect(coffee.revenue, closeTo(18, 0.001));
        final drinks = mix.singleWhere((c) => c.category == 'Soft drinks');
        expect(drinks.revenue, closeTo(15, 0.001));
        final other = mix.singleWhere((c) => c.category == 'Other');
        expect(other.revenue, closeTo(5, 0.001));
      },
    );

    test('deleted products keep their line snapshots in reports', () async {
      await journal.addOrder(
        order(
          id: 1,
          total: 9,
          items: const [
            OrderLineItem(
              productId: 'coffee-1',
              name: 'Espresso',
              quantity: 1,
              unitPrice: 9,
            ),
          ],
        ),
      );
      await products.delete('coffee-1');

      final top = await journal.topProducts(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      expect(top.single.name, 'Espresso');
    });
  });
}

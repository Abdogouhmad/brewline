import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/core/repositories/sales_query_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  group('sales log queries', () {
    late Database db;
    late OrderJournalRepository journal;
    late SalesQueryRepository sales;

    // A fixed local Monday and its neighbours.
    final monday = DateTime(2026, 8, 31, 9); // 2026-08-31 is a Monday
    final tuesday = DateTime(2026, 9, 1, 10);

    setUp(() async {
      db = await inMemoryDb();
      await deleteAllData(db);

      final products = ProductRepository(db);
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

      final staff = StaffRepository(db);
      await staff.upsert(
        StaffMember(
          id: 's1',
          username: 'waiter1',
          pinHash: 'deadbeef',
          name: 'Amina',
          createdAt: monday,
        ),
      );

      journal = OrderJournalRepository(db);
      sales = SalesQueryRepository(db);

      await journal.addOrder(
        OrderRecord(
          id: 1,
          createdAt: monday,
          waiterUsername: 'waiter1',
          total: 24,
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
        OrderRecord(
          id: 2,
          createdAt: tuesday,
          waiterUsername: 'waiter1',
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
    });

    tearDown(() => db.close());

    test(
      'lists every line newest-first, joining the staff display name',
      () async {
        final rows = await sales.getSales();
        expect(rows, hasLength(3));

        // Tuesday order (Cola) is newest; Monday order has 2 lines.
        expect(rows[0].orderId, 2);
        expect(rows[0].productName, 'Cola');
        expect(
          rows[0].waiter,
          'Amina',
        ); // joined from staff, falls back to username

        final mondayLines = rows.where((r) => r.orderId == 1).toList();
        expect(mondayLines, hasLength(2));
        expect(mondayLines.map((r) => r.productName).toSet(), {
          'Espresso',
          'Cola',
        });
      },
    );

    test('date window filters by order timestamp (exclusive end)', () async {
      final rows = await sales.getSales(from: monday, to: tuesday);
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.orderId == 1 || r.orderId == 2), isTrue);

      final before = await sales.getSales(to: monday);
      expect(before, isEmpty);
    });

    test('product and waiter filters combine', () async {
      final cola = await sales.getSales(productId: 'drink-1');
      expect(cola, hasLength(2));

      final amina = await sales.getSales(waiterUsername: 'waiter1');
      expect(amina, hasLength(3));

      final combined = await sales.getSales(
        productId: 'drink-1',
        waiterUsername: 'waiter1',
      );
      expect(combined, hasLength(2));
      expect(combined.every((r) => r.productName == 'Cola'), isTrue);
    });

    test('pagination: offset skips rows without pulling them all', () async {
      final page1 = await sales.getSales(limit: 2);
      final page2 = await sales.getSales(limit: 2, offset: 2);
      expect(page1, hasLength(2));
      expect(page2, hasLength(1));
      final seenIds = {
        ...page1.map((r) => r.orderId),
        ...page2.map((r) => r.orderId),
      };
      expect(seenIds, {1, 2});
    });

    test('ordersByWeekdayHour buckets Monday=0..Sunday=6 across weeks', () async {
      // Same time one week later lands in the same bucket; Wednesday@10 unused.
      final nextMonday = monday.add(const Duration(days: 7));
      await journal.addOrder(
        OrderRecord(
          id: 3,
          createdAt: nextMonday,
          total: 9,
          items: const [
            OrderLineItem(productId: 'x', name: 'X', quantity: 1, unitPrice: 9),
          ],
        ),
      );

      final buckets = await sales.ordersByWeekdayHour(
        monday.subtract(const Duration(hours: 1)),
        nextMonday.add(const Duration(days: 1)), // window spans both Mondays
      );

      expect(
        buckets.singleWhere((b) => b.weekday == 0 && b.hour == 9).orders,
        2, // monday 09:00 + nextMonday 09:00
      );
      expect(
        buckets.singleWhere((b) => b.weekday == 1 && b.hour == 10).orders,
        1, // tuesday 10:00 (Monday = 0 remap verified)
      );
      expect(buckets, hasLength(2));
    });
  });
}

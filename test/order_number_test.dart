import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  group('per-day order numbers', () {
    late Database db;
    late OrderJournalRepository journal;

    setUp(() async {
      db = await inMemoryDb();
      await deleteAllData(db);
      journal = OrderJournalRepository(db);
    });

    tearDown(() => db.close());

    OrderRecord order(int id, DateTime at, {double total = 10}) => OrderRecord(
      id: id,
      createdAt: at,
      total: total,
      items: const [
        OrderLineItem(productId: 'x', name: 'Item', quantity: 1, unitPrice: 10),
      ],
    );

    test(
      'addOrder assigns sequential per-day numbers and returns them',
      () async {
        final at = DateTime(2026, 8, 29, 12);
        final first = await journal.addOrder(order(1, at));
        final second = await journal.addOrder(order(2, at));

        expect(first.orderNumber, 1);
        expect(second.orderNumber, 2);
        expect(await journal.nextOrderNumber(at), 3);
        expect(await journal.nextOrderId(), 3);
      },
    );

    test('counting resets on the next local day', () async {
      final monday = DateTime(2026, 8, 31, 9);
      final tuesday = DateTime(2026, 9, 1, 9);

      await journal.addOrder(order(1, monday));
      await journal.addOrder(order(2, monday));
      await journal.addOrder(order(3, tuesday));
      final tuesdayNumber = await journal.nextOrderNumber(tuesday);

      expect(
        await journal.addOrder(order(4, monday)).then((r) => r.orderNumber),
        3,
      );
      expect(tuesdayNumber, 2);
    });

    test('an explicit orderNumber is preserved, not reassigned', () async {
      final at = DateTime(2026, 8, 29, 15);
      final kept = await journal.addOrder(
        OrderRecord(
          id: 1,
          createdAt: at,
          orderNumber: 42,
          total: 10,
          items: const [],
        ),
      );
      expect(kept.orderNumber, 42);
      // Counter was never touched, so the next free number is still 1.
      expect(await journal.nextOrderNumber(at), 1);
    });

    test('seed/historical rows keep orderNumber 0', () async {
      final at = DateTime(2026, 8, 29, 18);
      final seeded = await journal.addOrder(
        OrderRecord(id: 1, createdAt: at, total: 10, items: const []),
      );
      expect(seeded.orderNumber, 1); // fresh orders always get a number
      // Simulated historical import: pass an explicit 0 AND a completed number.
      final imported = await journal.addOrder(
        OrderRecord(
          id: 2,
          createdAt: at,
          orderNumber: 0,
          total: 10,
          items: const [],
        ),
      );
      expect(imported.orderNumber, 2);
      expect(imported.id, 2);
    });

    test('concurrent charges never collide on the same day', () async {
      final at = DateTime(2026, 8, 29, 20);
      final saved = await Future.wait([
        for (var i = 1; i <= 25; i++)
          journal.addOrder(
            OrderRecord(id: i, createdAt: at, total: 5, items: const []),
          ),
      ]);
      final numbers = saved.map((o) => o.orderNumber).toList()..sort();
      expect(numbers, List.generate(25, (i) => i + 1));
    });
  });
}

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/cashout_record.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/repositories/cashout_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Covers the `cashout_logs` ledger + derived shift summary at the repository
/// level: the single-write-path guarantee, transaction atomicity, the login-
/// derived shift window, and the filters/pagination the admin screen rides on.
void main() {
  sqfliteFfiInit();

  late Database db;
  late CashoutRepository cashout;
  late AuditRepository audit;

  Future<void> insertOrder({
    required int id,
    required DateTime createdAt,
    required String waiterUsername,
    required double total,
  }) {
    return db.insert('orders', {
      'id': id,
      'created_at': createdAt.millisecondsSinceEpoch,
      'waiter_username': waiterUsername,
      'total': total,
      'order_number': id,
    });
  }

  setUp(() async {
    db = await openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    await deleteAllData(db);
    cashout = CashoutRepository(db);
    audit = AuditRepository(db);
    // One staff account the FK constraint accepts.
    await db.insert('staff', {
      'id': 's-1',
      'username': 'john',
      'pin_hash': 'hash',
      'name': 'John Doe',
      'active': 1,
      'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    });
  });

  tearDown(() => db.close());

  CashoutRecord record({int orderCount = 5, int totalCents = 50000}) =>
      CashoutRecord(
        waiterId: 's-1',
        waiterUsername: 'john',
        waiterName: 'John Doe',
        shiftStart: DateTime(2026, 8, 29, 8, 0),
        shiftEnd: DateTime(2026, 8, 29, 21, 0),
        orderCount: orderCount,
        totalSalesCents: totalCents,
        cashCountedCents: 51200,
        cashVarianceCents: 1200,
        createdAt: DateTime(2026, 8, 29, 21, 0),
      );

  group('currentShiftSummary', () {
    test('derives shift start from the latest login and counts its orders',
        () async {
      await audit.logEvent(
        eventType: 'login',
        actor: 'john',
        at: DateTime(2026, 8, 29, 8, 0),
      );
      await insertOrder(
        id: 1,
        createdAt: DateTime(2026, 8, 29, 7, 0), // before shift → excluded
        waiterUsername: 'john',
        total: 99,
      );
      await insertOrder(
        id: 2,
        createdAt: DateTime(2026, 8, 29, 9, 0),
        waiterUsername: 'john',
        total: 12.5,
      );
      await insertOrder(
        id: 3,
        createdAt: DateTime(2026, 8, 29, 10, 30),
        waiterUsername: 'john',
        total: 7.0,
      );
      await insertOrder(
        id: 4,
        createdAt: DateTime(2026, 8, 29, 12, 0), // after `end` → excluded
        waiterUsername: 'john',
        total: 5,
      );

      final summary = await cashout.currentShiftSummary(
        waiterUsername: 'john',
        end: DateTime(2026, 8, 29, 11, 0),
      );

      expect(summary.shiftStart, DateTime(2026, 8, 29, 8, 0));
      expect(summary.shiftEnd, DateTime(2026, 8, 29, 11, 0));
      expect(summary.orderCount, 2);
      expect(summary.totalSalesCents, 1950); // 12.50 + 7.00
    });

    test('falls back to the start of the day when no login is recorded',
        () async {
      await insertOrder(
        id: 1,
        createdAt: DateTime(2026, 8, 29, 20, 0),
        waiterUsername: 'john',
        total: 10,
      );

      final summary = await cashout.currentShiftSummary(
        waiterUsername: 'john',
        end: DateTime(2026, 8, 29, 21, 0),
      );

      expect(summary.shiftStart, DateTime(2026, 8, 29, 0, 0));
      expect(summary.orderCount, 1);
      expect(summary.totalSalesCents, 1000);
    });
  });

  group('logCashout', () {
    test('writes exactly one ledger row plus one cashout audit event', () async {
      await cashout.logCashout(record());

      final ledger = await db.query('cashout_logs');
      expect(ledger, hasLength(1));
      expect(ledger.single['waiter_username'], 'john');
      expect(ledger.single['waiter_id'], 's-1');
      expect(ledger.single['total_sales_cents'], 50000);
      expect(ledger.single['cash_variance_cents'], 1200);

      final events = await audit.recent();
      expect(events, hasLength(1));
      expect(events.single.eventType, 'cashout');
      expect(events.single.actor, 'john');
    });

    test('is atomic: a failed ledger insert leaves no partial cashout', () async {
      // waiter_id 'ghost' violates the staff FK → the whole transaction rolls
      // back, so neither the ledger row nor the audit marker may appear.
      await expectLater(
        cashout.logCashout(
          CashoutRecord(
            waiterId: 'ghost',
            waiterUsername: 'john',
            waiterName: 'John Doe',
            shiftStart: DateTime(2026, 8, 29, 8, 0),
            shiftEnd: DateTime(2026, 8, 29, 21, 0),
            orderCount: 5,
            totalSalesCents: 50000,
            cashCountedCents: 51200,
            cashVarianceCents: 1200,
            createdAt: DateTime(2026, 8, 29, 21, 0),
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );

      expect(await db.query('cashout_logs'), isEmpty);
      expect(await audit.recent(), isEmpty);
    });
  });

  group('getCashoutLogs', () {
    test('returns finalized closes newest first and filters by waiter + date',
        () async {
      await cashout.logCashout(record(totalCents: 10000));
      // A second, later close by the same waiter.
      await cashout.logCashout(
        CashoutRecord(
          waiterId: 's-1',
          waiterUsername: 'john',
          waiterName: 'John Doe',
          shiftStart: DateTime(2026, 8, 30, 8, 0),
          shiftEnd: DateTime(2026, 8, 30, 20, 0),
          orderCount: 3,
          totalSalesCents: 25000,
          cashCountedCents: 25000,
          cashVarianceCents: 0,
          createdAt: DateTime(2026, 8, 30, 20, 0),
        ),
      );

      final all = await cashout.getCashoutLogs();
      expect(all, hasLength(2));
      expect(all.first.createdAt, DateTime(2026, 8, 30, 20, 0)); // newest first

      final august29 = await cashout.getCashoutLogs(
        from: DateTime(2026, 8, 29, 0, 0),
        to: DateTime(2026, 8, 30, 0, 0),
      );
      expect(august29, hasLength(1));
      expect(august29.single.totalSalesCents, 10000);
    });

    test('filters by waiter and paginates with limit/offset', () async {
      for (var i = 0; i < 3; i++) {
        await cashout.logCashout(record(totalCents: 1000 * (i + 1)));
      }

      final page1 = await cashout.getCashoutLogs(limit: 2, offset: 0);
      expect(page1, hasLength(2));
      expect(page1.first.totalSalesCents, 3000); // newest first
      expect(page1.last.totalSalesCents, 2000);

      final page2 = await cashout.getCashoutLogs(limit: 2, offset: 2);
      expect(page2, hasLength(1));
      expect(page2.single.totalSalesCents, 1000);
    });
  });
}
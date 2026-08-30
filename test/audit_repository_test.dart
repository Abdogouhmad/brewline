import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  group('audit event log', () {
    late Database db;
    late AuditRepository audit;

    setUp(() async {
      db = await inMemoryDb();
      await deleteAllData(db);
      audit = AuditRepository(db);
    });

    tearDown(() => db.close());

    test('logs login / logout / cashout with actor and metadata', () async {
      await audit.logEvent(
        eventType: 'login',
        actor: 'admin',
        at: DateTime(2026, 8, 29, 9),
      );
      await audit.logEvent(
        eventType: 'cashout',
        actor: 'waiter1',
        metadata: '{"gross":"350.00","orders":12}',
        at: DateTime(2026, 8, 29, 21),
      );
      await audit.logEvent(
        eventType: 'logout',
        actor: 'waiter1',
        at: DateTime(2026, 8, 29, 22),
      );

      final events = await audit.recent();
      expect(events, hasLength(3));
      expect(events[0].actor, 'waiter1'); // newest first
      expect(events[0].eventType, 'logout');
      expect(events[1].metadata, '{"gross":"350.00","orders":12}');
      expect(events[2].eventType, 'login');
    });

    test('recent filters by actor', () async {
      await audit.logEvent(
        eventType: 'login',
        actor: 'admin',
        at: DateTime(2026, 8, 29, 9),
      );
      await audit.logEvent(
        eventType: 'login',
        actor: 'waiter1',
        at: DateTime(2026, 8, 29, 9, 30),
      );
      await audit.logEvent(
        eventType: 'logout',
        actor: 'waiter1',
        at: DateTime(2026, 8, 29, 12),
      );

      final waiterEvents = await audit.recent(actor: 'waiter1');
      expect(waiterEvents, hasLength(2));
      expect(waiterEvents.every((e) => e.actor == 'waiter1'), isTrue);
      expect(await audit.recent(actor: 'admin'), hasLength(1));
    });

    test('rejects unknown event types (database CHECK constraint)', () async {
      const bad = {"event_type": 'refund', "actor": 'admin'};
      await expectLater(db.insert('audit_events', bad), throwsA(anything));
      expect(await audit.recent(), isEmpty);
    });
  });
}

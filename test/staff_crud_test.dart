import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  group('staff repository', () {
    late Database db;
    late StaffRepository repo;

    setUp(() async {
      db = await inMemoryDb();
      await deleteAllData(db);
      repo = StaffRepository(db);
    });

    StaffMember member({
      String id = 's-1',
      String username = 'waiter_a',
      String name = 'Waiter A',
      bool active = true,
    }) => StaffMember(
      id: id,
      username: username,
      pinHash: hashPin('1111'),
      name: name,
      active: active,
      createdAt: DateTime(2024, 1, 1),
    );

    test('upsert inserts, then updates in place (same id)', () async {
      await repo.upsert(member());
      expect(await repo.all(), hasLength(1));

      await repo.upsert(member(name: 'Waiter Renamed'));
      final all = await repo.all();
      expect(all.single.name, 'Waiter Renamed');
      expect(all, hasLength(1));
    });

    test('byUsername finds active accounts; null for unknown', () async {
      await repo.upsert(member());
      expect((await repo.byUsername('waiter_a'))?.name, 'Waiter A');
      expect(await repo.byUsername('nobody'), isNull);
    });

    test('setActive blocks sign-in but keeps the record', () async {
      await repo.upsert(member());
      await repo.setActive('s-1', false);

      // byUsername returns the record (callers check `active`), so sign-in is
      // refused where it matters while the row stays for history.
      expect((await repo.byUsername('waiter_a'))?.active, isFalse);
      final all = await repo.all();
      expect(all.single.active, isFalse);
      expect(await repo.active(), isEmpty);
    });

    test('delete removes the account entirely', () async {
      await repo.upsert(member());
      await repo.delete('s-1');
      expect(await repo.all(), isEmpty);
    });

    test('usernames stay unique (SQLite UNIQUE constraint)', () async {
      await repo.upsert(member());
      await expectLater(
        repo.upsert(member(id: 's-2')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}

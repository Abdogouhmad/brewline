import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/dev/dummy_data_seeder.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  Future<Database> inMemoryDb() =>
      openAppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

  test('seeder writes dummy admin + staff on a fresh install', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = await inMemoryDb();
    await deleteAllData(db);

    await seedDummyAccounts(prefs, db);

    expect(prefs.getString(kAdminUsernameKey), 'admin');
    expect(prefs.getString(kAdminPinHashKey), hashPin('1234'));

    final staff = StaffRepository(db);
    final members = await staff.all();
    expect(members.length, 3);
    expect((await staff.byUsername('waiter1'))?.pinHash, hashPin('1111'));
    expect((await staff.byUsername('waiter2'))?.pinHash, hashPin('2222'));
    expect((await staff.byUsername('waiter3'))?.pinHash, hashPin('3333'));
  });

  test(
    'seeder never overwrites a real admin account after onboarding',
    () async {
      SharedPreferences.setMockInitialValues({
        kOnboardingCompleteKey: true,
        kAdminUsernameKey: 'boss',
        kAdminPinHashKey: hashPin('9999'),
      });
      final prefs = await SharedPreferences.getInstance();
      final db = await inMemoryDb();
      await deleteAllData(db);

      await seedDummyAccounts(prefs, db);

      // Real admin left untouched.
      expect(prefs.getString(kAdminUsernameKey), 'boss');
      expect(prefs.getString(kAdminPinHashKey), hashPin('9999'));
    },
  );

  test('seeder is idempotent', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = await inMemoryDb();
    await deleteAllData(db);

    await seedDummyAccounts(prefs, db);
    await seedDummyAccounts(prefs, db);

    expect(prefs.getString(kAdminUsernameKey), 'admin');
    final staff = StaffRepository(db);
    expect((await staff.all()).length, 3);
  });

  test('sample sales seed only into an empty journal, once', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = await inMemoryDb();
    await deleteAllData(db);

    final ordersBefore = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM orders'),
    )!;
    expect(ordersBefore, 0);

    await seedDummyAccounts(prefs, db);
    final ordersAfter = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM orders'),
    )!;
    expect(ordersAfter, greaterThan(0));

    await seedDummyAccounts(prefs, db);
    final ordersAfterIdempotent = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM orders'),
    )!;
    expect(ordersAfterIdempotent, ordersAfter);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/staff_member.dart';

/// `staff` table mutations bump [staffMutationProvider] so staff lists and
/// shift cards recompute after create/edit/deactivate.
class StaffMutationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;

  /// Flips an account's `active` flag (blocks sign-in, keeps history).
  Future<void> setActive(String id, bool active) async {
    final repo = await ref.read(staffRepositoryProvider.future);
    await repo.setActive(id, active);
    state++;
  }

  /// Removes a member entirely. Prefer `setActive(false)` for departures.
  Future<void> delete(String id) async {
    final repo = await ref.read(staffRepositoryProvider.future);
    await repo.delete(id);
    state++;
  }
}

final staffMutationProvider = NotifierProvider<StaffMutationNotifier, int>(
  StaffMutationNotifier.new,
);

/// Writable handle to the `staff` table — the source of truth for POS
/// accounts (login + admin staff management).
class StaffRepository {
  final Database _db;

  const StaffRepository(this._db);

  /// Every staff member, sorted by display name.
  Future<List<StaffMember>> all() async {
    final rows = await _db.query('staff', orderBy: 'name COLLATE NOCASE');
    return rows.map(StaffMember.fromRow).toList();
  }

  /// Staff who are still allowed to sign in.
  Future<List<StaffMember>> active() async {
    final rows = await _db.query(
      'staff',
      where: 'active = 1',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(StaffMember.fromRow).toList();
  }

  Future<StaffMember?> byUsername(String username) async {
    final rows = await _db.query(
      'staff',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return rows.isEmpty ? null : StaffMember.fromRow(rows.first);
  }

  /// Inserts a new member or updates an existing one (matched by id).
  Future<void> upsert(StaffMember member) async {
    final existing = await _db.query(
      'staff',
      where: 'id = ?',
      whereArgs: [member.id],
      limit: 1,
    );
    if (existing.isEmpty) {
      await _db.insert('staff', member.toRow());
    } else {
      await _db.update(
        'staff',
        member.toRow(),
        where: 'id = ?',
        whereArgs: [member.id],
      );
    }
  }

  /// Removes a member entirely. Deactivation (see [setActive]) is preferred
  /// for departing staff so their sales history stays attributed.
  Future<void> delete(String id) async {
    await _db.delete('staff', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setActive(String id, bool active) async {
    await _db.update(
      'staff',
      {'active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final staffRepositoryProvider = FutureProvider<StaffRepository>(
  (ref) async => StaffRepository(await ref.watch(appDatabaseProvider.future)),
);

/// Full staff roster — recomputes on any staff write.
final staffListProvider = FutureProvider<List<StaffMember>>((ref) async {
  ref.watch(staffMutationProvider);
  return (await ref.watch(staffRepositoryProvider.future)).all();
});

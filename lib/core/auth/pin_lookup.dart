import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart'
    show kAdminPinHashKey, kAdminUsernameKey;

/// Central PIN lookup and uniqueness enforcement.
///
/// ## Why there is no database `UNIQUE` constraint on PIN hashes
///
/// PINs are stored as SHA-256 hashes (see `password_hash.dart`). Because each
/// user's hash is computed from the same raw PIN, two users who choose the same
/// PIN produce **identical** hash strings. A `UNIQUE` index on the stored hash
/// column *would* catch that collision — but only because this project uses
/// unsalted SHA-256. If per-user salts are ever introduced (which is the
/// correct long-term evolution for a real auth system), the same raw PIN
/// produces **different** stored hashes for every user, and a `UNIQUE` index
/// would silently pass both rows through — completely defeating the uniqueness
/// requirement without any error.
///
/// To stay correct regardless of hashing strategy, uniqueness is enforced in
/// **application code**: every candidate PIN is verified against every active
/// user's stored hash before it is accepted. This scan is O(n) in the number
/// of active users, which for a café's staff (typically < 20) is comfortably
/// sub-second. The trade-off is deliberate — a pepper-based O(1) lookup would
/// add a second hash column and secret-management burden that isn't worth it at
/// café scale.
///
/// Both [findUserByPin] (login) and [isPinTaken] (PIN-setting) live here and
/// are the **only** code paths that scan + verify PINs. Do not duplicate this
/// loop elsewhere.

/// Represents a user found by PIN lookup — either the admin or a staff member.
class PinLookupResult {
  final Role role;
  final String userId;
  final String username;

  const PinLookupResult({
    required this.role,
    required this.userId,
    required this.username,
  });
}

/// Scans all active users and returns the one whose stored PIN hash matches
/// [pin], or `null` if no match is found.
///
/// Checks the admin account (SharedPreferences) first, then scans the staff
/// table. This is the single login-lookup path — called by [authProvider].
Future<PinLookupResult?> findUserByPin(
  String pin, {
  required SharedPreferences prefs,
  required StaffRepository staffRepo,
}) async {
  final enteredHash = hashPin(pin);

  // 1. Admin — the single stored account in SharedPreferences.
  final storedUsername = prefs.getString(kAdminUsernameKey);
  final storedHash = prefs.getString(kAdminPinHashKey);
  if (storedUsername != null && storedHash != null && storedHash == enteredHash) {
    return PinLookupResult(
      role: Role.admin,
      userId: 'admin',
      username: storedUsername,
    );
  }

  // 2. Staff — scan active members in the SQLite table.
  final activeStaff = await staffRepo.active();
  for (final member in activeStaff) {
    if (member.pinHash == enteredHash) {
      return PinLookupResult(
        role: Role.waiter,
        userId: member.id,
        username: member.username,
      );
    }
  }

  return null;
}

/// Returns `true` if [candidatePin] matches any existing active user's PIN.
///
/// [excludingUserId] allows a user's own unchanged PIN to pass during edits
/// (otherwise editing a waiter without changing their PIN would flag itself
/// as a duplicate). For the admin account, pass `'admin'` as the exclude ID.
///
/// Call this **before** writing a new hash — on onboarding, waiter creation,
/// waiter PIN reset, and any future "change my PIN" flow.
Future<bool> isPinTaken(
  String candidatePin, {
  String? excludingUserId,
  required SharedPreferences prefs,
  required StaffRepository staffRepo,
}) async {
  final candidateHash = hashPin(candidatePin);

  // Check admin account.
  if (excludingUserId != 'admin') {
    final storedHash = prefs.getString(kAdminPinHashKey);
    if (storedHash != null && storedHash == candidateHash) return true;
  }

  // Check all active staff.
  final activeStaff = await staffRepo.active();
  for (final member in activeStaff) {
    if (excludingUserId != null && member.id == excludingUserId) continue;
    if (member.pinHash == candidateHash) return true;
  }

  return false;
}

/// Riverpod provider that exposes [findUserByPin] with injected dependencies.
final pinLookupProvider = Provider<Future<PinLookupResult?> Function(String)>(
  (ref) {
    return (String pin) async {
      final prefs = ref.read(sharedPreferencesProvider);
      final staffRepo = await ref.read(staffRepositoryProvider.future);
      return findUserByPin(pin, prefs: prefs, staffRepo: staffRepo);
    };
  },
);

/// Riverpod provider that exposes [isPinTaken] with injected dependencies.
final isPinTakenProvider = Provider<
  Future<bool> Function(String, {String? excludingUserId})
>((ref) {
  return (
    String candidatePin, {
    String? excludingUserId,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final staffRepo = await ref.read(staffRepositoryProvider.future);
    return isPinTaken(
      candidatePin,
      excludingUserId: excludingUserId,
      prefs: prefs,
      staffRepo: staffRepo,
    );
  };
});

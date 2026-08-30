import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

import 'auth_state.dart';
import '../../onboarding/providers/onboarding_provider.dart'
    show kAdminUsernameKey, kAdminPinHashKey;

/// Thrown by [AuthNotifier.login] when credentials are invalid.
///
/// Carries a deliberately generic message ("Incorrect username or PIN") so the
/// UI cannot reveal whether the username or the PIN was wrong — a security
/// choice, not an oversight (a potential attacker shouldn't learn which part
/// of the credential was incorrect).
class AuthException implements Exception {
  final String message;
  final StackTrace stackTrace;

  AuthException(this.message, this.stackTrace);
}

/// Holds the current session (`null` = logged out) and owns login/logout.
///
/// **Unified login (role auto-detected):** there is exactly one login — a
/// username + 4-digit PIN. The role is derived from *who the username belongs
/// to*, never chosen by the user:
///  1. The single admin account (created during onboarding, or the debug
///     seeder) is stored under `admin_username` / `admin_pin_hash` in
///     SharedPreferences. A username matching it and verifying its hash signs
///     in as admin.
///  2. Everyone else is looked up in the waiters' `staff` SQLite table (seeded
///     in debug, created by the admin via the Staff tab), keyed by a unique
///     username holding the hashed PIN.
///
/// The *generic error message* is enforced here in one place — both failure
/// paths (unknown username, wrong PIN) throw the same [AuthException] so the
/// UI never distinguishes them.
class AuthNotifier extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async => null;

  Future<void> login({required String username, required String pin}) async {
    state = const AsyncValue.loading();
    try {
      final session = await _authenticate(username: username, pin: pin);
      // Session/money ledger: record who got in, so the audit stream can
      // answer "who was signed in when" without a session table.
      await _log('login', session.username);
      state = AsyncData(session);
    } on AuthException catch (e) {
      state = AsyncError(e, e.stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    final actor = state.value?.username;
    // Ledger write happens before the session clears so we still know who
    // this logout belonged to.
    await _log('logout', actor);
    state = const AsyncData(null);
  }

  Future<void> _log(String eventType, String? actor) async {
    if (actor == null) return; // Nothing to record for a never-logged-in state.
    final audit = await ref.read(auditRepositoryProvider.future);
    await audit.logEvent(eventType: eventType, actor: actor);
  }

  Future<AuthState> _authenticate({
    required String username,
    required String pin,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final enteredHash = hashPin(pin);
    final trimmed = username.trim();

    // 1. Admin — the single stored account, matched first.
    final storedUsername = prefs.getString(kAdminUsernameKey);
    final storedHash = prefs.getString(kAdminPinHashKey);
    if (storedUsername != null &&
        storedUsername == trimmed &&
        storedHash != null &&
        storedHash == enteredHash) {
      return AuthState(
        role: Role.admin,
        userId: 'admin',
        username: storedUsername,
      );
    }

    // 2. Waiter — looked up against the staff table.
    final staff = await ref.read(staffRepositoryProvider.future);
    final member = await staff.byUsername(trimmed);
    if (member != null && member.active && member.pinHash == enteredHash) {
      return AuthState(
        role: Role.waiter,
        userId: member.id,
        username: member.username,
      );
    }

    throw AuthException('Incorrect username or PIN', StackTrace.current);
  }
}

/// The current session — `null` while logged out.
///
/// Read by the startup router to skip login when already signed in and by both
/// dashboards to know who's on shift.
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState?>(
  AuthNotifier.new,
);

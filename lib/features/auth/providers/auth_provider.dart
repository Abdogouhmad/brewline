import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

import 'auth_state.dart';
import '../../onboarding/providers/onboarding_provider.dart'
    show kAdminUsernameKey, kAdminPinHashKey;

/// SharedPreferences key holding the JSON map of waiter username -> hashed PIN.
const String kWaiterAccountsKey = 'waiter_accounts';

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
/// **Admin vs waiter lookup:** the app stores a single admin account (created
/// during onboarding) under `admin_username` / `admin_pin_hash`, and a JSON map
/// of waiter accounts (seeded in debug, later created by the admin) under
/// `waiter_accounts`. Login reads the record for the requested [Role], hashes
/// the entered PIN with [hashPin] and compares it to the stored digest.
///
/// The *generic error message* is enforced here in one place — both failure
/// paths (unknown username, wrong PIN) throw the same [AuthException] so the
/// UI never distinguishes them.
class AuthNotifier extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async => null;

  Future<void> login({
    required Role role,
    required String username,
    required String pin,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _authenticate(role: role, username: username, pin: pin);
      state = AsyncData(session);
    } on AuthException catch (e) {
      state = AsyncError(e, e.stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncData(null);
  }

  Future<AuthState> _authenticate({
    required Role role,
    required String username,
    required String pin,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final enteredHash = hashPin(pin);

    final bool ok;
    switch (role) {
      case Role.admin:
        final storedUsername = prefs.getString(kAdminUsernameKey);
        final storedHash = prefs.getString(kAdminPinHashKey);
        ok = storedUsername != null &&
            storedUsername == username.trim() &&
            storedHash != null &&
            storedHash == enteredHash;
        if (ok) {
          return AuthState(
            role: role,
            userId: 'admin',
            username: storedUsername,
          );
        }
      case Role.waiter:
        final waiters = _readWaiters(prefs.getString(kWaiterAccountsKey));
        final storedHash = waiters[username.trim()];
        ok = storedHash != null && storedHash == enteredHash;
        if (ok) {
          return AuthState(
            role: role,
            userId: 'waiter-$username',
            username: username.trim(),
          );
        }
    }

    throw AuthException(
      'Incorrect username or PIN',
      StackTrace.current,
    );
  }

  static Map<String, String> _readWaiters(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map((key, value) => MapEntry('$key', '$value'));
  }
}

/// The current session — `null` while logged out.
///
/// Read by the startup router to skip login when already signed in and by both
/// dashboards to know who's on shift.
final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState?>(AuthNotifier.new);

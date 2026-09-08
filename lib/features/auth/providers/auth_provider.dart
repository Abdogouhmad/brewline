import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/auth/pin_lookup.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/credential_store.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

import 'auth_state.dart';

/// Thrown by [AuthNotifier.login] when credentials are invalid.
///
/// Carries a deliberately generic message ("Incorrect PIN") so the UI cannot
/// reveal which part of the credential was wrong — a security choice, not an
/// oversight (a potential attacker shouldn't learn which PINs are close).
class AuthException implements Exception {
  final String message;
  final StackTrace stackTrace;

  AuthException(this.message, this.stackTrace);
}

/// Holds the current session (`null` = logged out) and owns login/logout.
///
/// **PIN-only login:** there is exactly one login — a 4-digit PIN. No username,
/// no role selector. The system identifies who is signing in (and therefore
/// which dashboard to route to) purely from the PIN:
///  1. The PIN is scanned against every active user (admin + staff) via
///     [findUserByPin] until a hash match is found.
///  2. No match → generic [AuthException] with "Incorrect PIN".
///  3. Match → session created with the matched user's role and identity.
///
/// Every PIN in the system must be unique across all users (enforced at
/// PIN-setting time by `isPinTaken` in `pin_lookup.dart`), so a single match
/// is always definitive.
class AuthNotifier extends AsyncNotifier<AuthState?> {
  /// Max consecutive failed PIN attempts before a lockout kicks in.
  static const int _maxAttempts = 5;

  /// How long a lockout lasts once triggered.
  static const Duration _lockoutDuration = Duration(minutes: 5);

  static const _attemptsKey = 'auth_failed_attempts';
  static const _lockoutUntilKey = 'auth_lockout_until';

  @override
  Future<AuthState?> build() async => null;

  /// Authenticates by PIN alone. The role is auto-detected from whichever
  /// user's stored hash matches the entered PIN.
  ///
  /// Enforces a brute-force lockout: after [_maxAttempts] consecutive failures
  /// the device is barred for [_lockoutDuration], making programmatic PIN
  /// guessing impractical even with physical access. The failing attempt
  /// returns immediately — the lockout timestamp is checked on entry, so the
  /// UI never freezes for the whole barring duration.
  Future<void> login({required String pin}) async {
    final prefs = ref.read(sharedPreferencesProvider);

    // Honour an active lockout before even attempting the lookup.
    final lockoutUntil = prefs.getInt(_lockoutUntilKey);
    if (lockoutUntil != null &&
        DateTime.now().millisecondsSinceEpoch < lockoutUntil) {
      state = AsyncError(
        AuthException('Too many attempts. Try again later.', StackTrace.current),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final credentials = ref.read(credentialStoreProvider);
      final staffRepo = await ref.read(staffRepositoryProvider.future);
      final result = await findUserByPin(
        pin,
        credentials: credentials,
        staffRepo: staffRepo,
      );

      if (result == null) {
        await _recordFailure(prefs);
        throw AuthException('Incorrect PIN', StackTrace.current);
      }

      // Success — clear any accumulated failure state.
      await prefs.remove(_attemptsKey);
      await prefs.remove(_lockoutUntilKey);

      await _log('login', result.username);
      state = AsyncData(
        AuthState(
          role: result.role,
          userId: result.userId,
          username: result.username,
        ),
      );
    } on AuthException catch (e) {
      state = AsyncError(e, e.stackTrace);
      rethrow;
    }
  }

  /// Persists the incremented failure count and, if the lockout threshold is
  /// reached, the time until the device is barred.
  Future<void> _recordFailure(SharedPreferences prefs) async {
    final attempts = (prefs.getInt(_attemptsKey) ?? 0) + 1;
    await prefs.setInt(_attemptsKey, attempts);
    if (attempts >= _maxAttempts) {
      await prefs.setInt(
        _lockoutUntilKey,
        DateTime.now().add(_lockoutDuration).millisecondsSinceEpoch,
      );
      await prefs.remove(_attemptsKey);
    }
  }

  Future<void> logout() async {
    final actor = state.value?.username;
    await _log('logout', actor);
    state = const AsyncData(null);
  }

  Future<void> _log(String eventType, String? actor) async {
    if (actor == null) return;
    final audit = await ref.read(auditRepositoryProvider.future);
    await audit.logEvent(eventType: eventType, actor: actor);
  }
}

/// The current session — `null` while logged out.
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState?>(
  AuthNotifier.new,
);

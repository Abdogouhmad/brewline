import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/auth/pin_lookup.dart';
import 'package:brewline/core/repositories/audit_repository.dart';

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
///     [pinLookupProvider] until a hash match is found.
///  2. No match → generic [AuthException] with "Incorrect PIN".
///  3. Match → session created with the matched user's role and identity.
///
/// Every PIN in the system must be unique across all users (enforced at
/// PIN-setting time by `isPinTaken` in `pin_lookup.dart`), so a single match
/// is always definitive.
class AuthNotifier extends AsyncNotifier<AuthState?> {
  @override
  Future<AuthState?> build() async => null;

  /// Authenticates by PIN alone. The role is auto-detected from whichever
  /// user's stored hash matches the entered PIN.
  Future<void> login({required String pin}) async {
    state = const AsyncValue.loading();
    try {
      final findUser = ref.read(pinLookupProvider);
      final result = await findUser(pin);

      if (result == null) {
        throw AuthException('Incorrect PIN', StackTrace.current);
      }

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

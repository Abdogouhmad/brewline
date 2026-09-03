import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/auth/pin_lookup.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

import 'onboarding_state.dart';

/// SharedPreferences key marking that one-time onboarding has been completed.
const String kOnboardingCompleteKey = 'onboarding_complete';

/// SharedPreferences key holding the admin's username (see admin_pin_hash).
const String kAdminUsernameKey = 'admin_username';

/// SharedPreferences key holding the hashed admin PIN (see hashPin in
/// core/security/password_hash.dart).
const String kAdminPinHashKey = 'admin_pin_hash';

/// Whether onboarding has been completed (persisted).
final onboardingCompleteProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(kOnboardingCompleteKey) ?? false;
});

/// Notifier that drives the onboarding form: field updates, inline
/// validation, and submit-to-storage.
///
/// The PIN step calls `isPinTaken` before writing the hash (§3.2 of the
/// PIN-only login spec) to enforce global uniqueness from the start.
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void setUsername(String value) {
    state = state.copyWith(
      username: value,
      clearUsernameError: true,
      clearSubmitError: true,
    );
    state = state.validate();
  }

  void setPin(String value) {
    state = state.copyWith(
      pin: value,
      clearPinError: true,
      clearSubmitError: true,
      clearPinTakenError: true,
    );
    state = state.validate();
  }

  void setConfirmPin(String value) {
    state = state.copyWith(
      confirmPin: value,
      clearConfirmError: true,
      clearSubmitError: true,
    );
    state = state.validate();
  }

  Future<void> submit() async {
    if (!state.isValid) return;
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    try {
      // Enforce global PIN uniqueness before persisting (§3.2).
      final taken = await ref.read(isPinTakenProvider)(state.pin);
      if (taken) {
        state = state.copyWith(
          isSubmitting: false,
          pinTakenError: 'That PIN is already in use — pick a different one',
        );
        return;
      }

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(kAdminUsernameKey, state.username.trim());
      await prefs.setString(kAdminPinHashKey, hashPin(state.pin));
      await prefs.setBool(kOnboardingCompleteKey, true);
      ref.invalidate(onboardingCompleteProvider);
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: 'Setup failed. Please try again.',
      );
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

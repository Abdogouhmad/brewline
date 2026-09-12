import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/auth/pin_lookup.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/credential_store.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

import 'onboarding_state.dart';

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
      final credentials = ref.read(credentialStoreProvider);
      final staffRepo = await ref.read(staffRepositoryProvider.future);
      final taken = await isPinTaken(
        state.pin,
        credentials: credentials,
        staffRepo: staffRepo,
      );
      if (taken) {
        state = state.copyWith(
          isSubmitting: false,
          pinTakenError: OnboardingError.pinTaken,
        );
        return;
      }

      final salt = generateSalt();
      final prefs = ref.read(sharedPreferencesProvider);
      await credentials.write(
        AdminCredential(
          username: state.username.trim(),
          pinHash: hashPin(state.pin, salt),
          pinSalt: salt,
        ),
      );
      await prefs.setBool(kOnboardingCompleteKey, true);
      ref.invalidate(onboardingCompleteProvider);
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: OnboardingError.setupFailed,
      );
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

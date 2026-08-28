import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'onboarding_state.dart';

const String _kOnboardingCompleteKey = 'onboarding_complete';

/// Whether onboarding has been completed (persisted).
final onboardingCompleteProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_kOnboardingCompleteKey) ?? false;
});

/// Notifier that drives the onboarding form: field updates, inline
/// validation, and submit-to-storage.
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
      final prefs = ref.read(sharedPreferencesProvider);
      // TODO: hash PIN and store admin credential when auth service exists.
      await prefs.setBool(_kOnboardingCompleteKey, true);
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
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';

import 'auth_provider.dart';

/// Local, screen-only state for the login form.
///
/// Kept separate from the session ([authProvider]) so in-progress input —
/// typed [username] and [pin] — never races with or clobbers the persisted
/// session, mirroring the separation used in the onboarding form.
class LoginFormState {
  final String username;
  final String pin;
  final String? submitError;
  final bool isSubmitting;

  /// Drives the dusting/shake on the PIN keypad after a failed attempt.
  final bool hasError;

  /// Bumped on each failure so [PinKeypadField] clears its digits without
  /// losing the keypad instance (which would swallow the shake animation).
  final int resetSignal;

  const LoginFormState({
    this.username = '',
    this.pin = '',
    this.submitError,
    this.isSubmitting = false,
    this.hasError = false,
    this.resetSignal = 0,
  });

  /// Submit is only allowed once a username and a full-length PIN are present.
  /// The role is auto-detected from the username, so no role is tracked here.
  bool get canSubmit =>
      username.trim().isNotEmpty && pin.length >= kAdminPinLength;

  LoginFormState copyWith({
    String? username,
    String? pin,
    String? submitError,
    bool clearSubmitError = false,
    bool? isSubmitting,
    bool? hasError,
    int? resetSignal,
  }) => LoginFormState(
    username: username ?? this.username,
    pin: pin ?? this.pin,
    submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    isSubmitting: isSubmitting ?? this.isSubmitting,
    hasError: hasError ?? this.hasError,
    resetSignal: resetSignal ?? this.resetSignal,
  );
}

class LoginFormNotifier extends Notifier<LoginFormState> {
  @override
  LoginFormState build() => const LoginFormState();

  void setUsername(String value) {
    state = state.copyWith(
      username: value,
      clearSubmitError: true,
      // Bring the keypad out of the error state so the shake can re-trigger
      // and the dots return to their normal color on the next attempt.
      hasError: false,
    );
  }

  void setPin(String value) {
    state = state.copyWith(pin: value, clearSubmitError: true, hasError: false);
  }

  Future<void> submit() async {
    if (!state.canSubmit || state.isSubmitting) return;
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
      hasError: false,
    );

    try {
      await ref
          .read(authProvider.notifier)
          .login(username: state.username, pin: state.pin);
      state = state.copyWith(isSubmitting: false);
    } catch (_) {
      // Failure is surfaced generically (see authProvider); clear the PIN and
      // shake the keypad, but keep the username so a typo is easy to fix. The
      // pin is reset here (not via onChanged) so the error text survives.
      state = state.copyWith(
        isSubmitting: false,
        pin: '',
        submitError: 'Incorrect username or PIN',
        hasError: true,
        resetSignal: state.resetSignal + 1,
      );
    }
  }
}

/// Screen-local input + validation state for the login form.
///
/// Auto-disposed so it resets whenever `LoginPage` leaves the tree (e.g. after
/// logout), so the next sign-in starts from a clean username/PIN.
final loginFormProvider =
    NotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>(
      LoginFormNotifier.new,
    );

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';

import 'auth_provider.dart';

/// Maximum consecutive failed PIN attempts before the keypad is temporarily
/// disabled. Resent in memory only — resets on app restart, which is the
/// intended behaviour for a physical-device deterrent (§6 of the spec).
const int _maxAttempts = 5;

/// Cooldown duration after hitting the attempt limit.
const Duration _cooldownDuration = Duration(seconds: 30);

/// Local, screen-only state for the login form.
///
/// Kept separate from the session ([authProvider]) so in-progress input —
/// typed PIN — never races with or clobbers the persisted session.
class LoginFormState {
  final String pin;
  final String? submitError;
  final bool isSubmitting;

  /// Drives the dusting/shake on the PIN keypad after a failed attempt.
  final bool hasError;

  /// Bumped on each failure so [PinKeypadField] clears its digits without
  /// losing the keypad instance (which would swallow the shake animation).
  final int resetSignal;

  /// Consecutive failed attempts. When [_maxAttempts] is reached the keypad
  /// is disabled for [_cooldownDuration].
  final int failedAttempts;

  /// Remaining cooldown seconds. Positive → keypad disabled.
  final int cooldownRemaining;

  const LoginFormState({
    this.pin = '',
    this.submitError,
    this.isSubmitting = false,
    this.hasError = false,
    this.resetSignal = 0,
    this.failedAttempts = 0,
    this.cooldownRemaining = 0,
  });

  /// Submit is allowed once a full-length PIN is present and we're not
  /// rate-limited or already submitting.
  bool get canSubmit =>
      pin.length >= kAdminPinLength && !isThrottled && !isSubmitting;

  /// Whether the keypad is currently locked out after too many failures.
  bool get isThrottled => cooldownRemaining > 0;

  LoginFormState copyWith({
    String? pin,
    String? submitError,
    bool clearSubmitError = false,
    bool? isSubmitting,
    bool? hasError,
    int? resetSignal,
    int? failedAttempts,
    int? cooldownRemaining,
  }) => LoginFormState(
    pin: pin ?? this.pin,
    submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    isSubmitting: isSubmitting ?? this.isSubmitting,
    hasError: hasError ?? this.hasError,
    resetSignal: resetSignal ?? this.resetSignal,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
  );
}

class LoginFormNotifier extends Notifier<LoginFormState> {
  Timer? _cooldownTimer;

  @override
  LoginFormState build() {
    // Cancel any in-flight cooldown timer when this provider is destroyed.
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const LoginFormState();
  }

  void setPin(String value) {
    state = state.copyWith(pin: value, clearSubmitError: true, hasError: false);
  }

  /// Called by the UI when [PinKeypadField] completes all digits.
  /// Auto-submits if throttling is not active.
  void onPinCompleted(String value) {
    if (state.canSubmit) {
      submit();
    }
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
      hasError: false,
    );

    try {
      await ref.read(authProvider.notifier).login(pin: state.pin);
      if (!ref.mounted) return;
      state = state.copyWith(isSubmitting: false);
    } catch (_) {
      if (!ref.mounted) return;
      final newFailed = state.failedAttempts + 1;
      final shouldThrottle = newFailed >= _maxAttempts;

      state = state.copyWith(
        isSubmitting: false,
        pin: '',
        submitError: 'Incorrect PIN',
        hasError: true,
        resetSignal: state.resetSignal + 1,
        failedAttempts: newFailed,
      );

      if (shouldThrottle) {
        _startCooldown();
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(cooldownRemaining: _cooldownDuration.inSeconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!ref.mounted) {
        timer.cancel();
        return;
      }
      final remaining = state.cooldownRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(
          cooldownRemaining: 0,
          failedAttempts: 0,
          clearSubmitError: true,
        );
      } else {
        state = state.copyWith(cooldownRemaining: remaining);
      }
    });
  }
}

/// Screen-local input + validation state for the PIN-only login form.
final loginFormProvider =
    NotifierProvider.autoDispose<LoginFormNotifier, LoginFormState>(
      LoginFormNotifier.new,
    );

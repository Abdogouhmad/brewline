import 'package:brewline/core/constants/app_sizes.dart';

/// Machine-readable codes for the onboarding form's inline validation errors.
///
/// Stored on [OnboardingState] instead of raw English strings so the copy can
/// be localized in the widget layer — code in the provider, display string in
/// the UI (improve.md §4). Translate each code in `onboarding_form.dart`.
enum OnboardingError { usernameInvalid, pinLength, pinMismatch, pinTaken, setupFailed }

/// Mutable state for the onboarding form.
class OnboardingState {
  final String username;
  final String pin;
  final String confirmPin;
  final OnboardingError? usernameError;
  final OnboardingError? pinError;
  final OnboardingError? confirmError;
  final OnboardingError? pinTakenError;
  final bool isSubmitting;
  final OnboardingError? submitError;

  const OnboardingState({
    this.username = '',
    this.pin = '',
    this.confirmPin = '',
    this.usernameError,
    this.pinError,
    this.confirmError,
    this.pinTakenError,
    this.isSubmitting = false,
    this.submitError,
  });

  OnboardingState copyWith({
    String? username,
    String? pin,
    String? confirmPin,
    OnboardingError? usernameError,
    bool clearUsernameError = false,
    OnboardingError? pinError,
    bool clearPinError = false,
    OnboardingError? confirmError,
    bool clearConfirmError = false,
    OnboardingError? pinTakenError,
    bool clearPinTakenError = false,
    bool? isSubmitting,
    OnboardingError? submitError,
    bool clearSubmitError = false,
  }) => OnboardingState(
    username: username ?? this.username,
    pin: pin ?? this.pin,
    confirmPin: confirmPin ?? this.confirmPin,
    usernameError: clearUsernameError
        ? null
        : (usernameError ?? this.usernameError),
    pinError: clearPinError ? null : (pinError ?? this.pinError),
    confirmError: clearConfirmError
        ? null
        : (confirmError ?? this.confirmError),
    pinTakenError: clearPinTakenError
        ? null
        : (pinTakenError ?? this.pinTakenError),
    isSubmitting: isSubmitting ?? this.isSubmitting,
    submitError: clearSubmitError ? null : (submitError ?? this.submitError),
  );

  /// Username: 3–24 chars, letters/numbers/underscore only.
  bool get _isUsernameValid {
    final trimmed = username.trim();
    if (trimmed.length < 3 || trimmed.length > 24) return false;
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed);
  }

  /// PIN: exactly [kAdminPinLength] digits.
  bool get _isPinValid =>
      pin.length == kAdminPinLength && RegExp(r'^\d+$').hasMatch(pin);

  /// Confirm PIN matches PIN.
  bool get _isConfirmValid => confirmPin == pin && confirmPin.isNotEmpty;

  bool get isValid => _isUsernameValid && _isPinValid && _isConfirmValid;

  /// Returns a copy with inline validation errors populated.
  OnboardingState validate() => copyWith(
    clearUsernameError: true,
    clearPinError: true,
    clearConfirmError: true,
    usernameError: username.isEmpty
        ? null
        : (_isUsernameValid ? null : OnboardingError.usernameInvalid),
    pinError: pin.isEmpty
        ? null
        : (_isPinValid ? null : OnboardingError.pinLength),
    confirmError: confirmPin.isEmpty
        ? null
        : (_isConfirmValid ? null : OnboardingError.pinMismatch),
  );
}

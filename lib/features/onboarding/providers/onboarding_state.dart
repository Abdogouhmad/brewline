import 'package:brewline/core/constants/app_sizes.dart';

/// Mutable state for the onboarding form.
class OnboardingState {
  final String username;
  final String pin;
  final String confirmPin;
  final String? usernameError;
  final String? pinError;
  final String? confirmError;
  final String? pinTakenError;
  final bool isSubmitting;
  final String? submitError;

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
    String? usernameError,
    bool clearUsernameError = false,
    String? pinError,
    bool clearPinError = false,
    String? confirmError,
    bool clearConfirmError = false,
    String? pinTakenError,
    bool clearPinTakenError = false,
    bool? isSubmitting,
    String? submitError,
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
        : (_isUsernameValid ? null : '3–24 characters, letters, numbers, or _'),
    pinError: pin.isEmpty
        ? null
        : (_isPinValid ? null : 'PIN must be exactly $kAdminPinLength digits'),
    confirmError: confirmPin.isEmpty
        ? null
        : (_isConfirmValid ? null : "PINs don't match"),
  );
}

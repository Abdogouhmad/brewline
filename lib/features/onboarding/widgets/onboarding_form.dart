import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/shared/widgets/shared/app_text_field.dart';
import 'package:brewline/shared/widgets/shared/pin_keypad_field.dart';

/// The onboarding form: username → PIN → confirm PIN → finish button.
///
/// Uses a single [PinKeypadField] slot that transitions between
/// PIN entry and confirm-PIN entry — never both visible at once,
/// so the form fits on mobile without scrolling.
class OnboardingForm extends ConsumerStatefulWidget {
  const OnboardingForm({super.key});

  @override
  ConsumerState<OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends ConsumerState<OnboardingForm> {
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final pinComplete = state.pin.length >= kAdminPinLength;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Space.x2l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Username ---
          AppTextField(
            label: 'Username',
            hintText: 'Choose a username',
            errorText: state.usernameError,
            controller: _usernameController,
            keyboardType: TextInputType.text,
            autofillHints: const [AutofillHints.username],
            onChanged: notifier.setUsername,
          ),
          SizedBox(height: Space.xl),

          // --- Single PIN slot: swaps between "set" and "confirm" ---
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: pinComplete
                ? _PinSection(
                    key: const ValueKey('confirm'),
                    label: 'Confirm your PIN',
                    hasError: state.confirmError != null,
                    onChanged: notifier.setConfirmPin,
                    onCompleted: (_) {},
                  )
                : _PinSection(
                    key: const ValueKey('pin'),
                    label: 'Set your PIN',
                    hasError: state.pinError != null,
                    onChanged: notifier.setPin,
                    onCompleted: (_) {},
                  ),
          ),

          // Error text for whichever PIN step is active
          if (!pinComplete && state.pinError != null) ...[
            SizedBox(height: Space.sm),
            Text(
              state.pinError!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (pinComplete && state.confirmError != null) ...[
            SizedBox(height: Space.sm),
            Text(
              state.confirmError!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: Space.xl),

          // --- Submit ---
          FilledButton(
            onPressed: state.isValid && !state.isSubmitting
                ? () => notifier.submit()
                : null,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Rounded.xl),
              ),
            ),
            child: state.isSubmitting
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    'Finish setup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
          if (state.submitError != null) ...[
            SizedBox(height: Space.md),
            Text(
              state.submitError!,
              style: TextStyle(color: colorScheme.error, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Wraps [PinKeypadField] with its own key so [AnimatedSwitcher] can
/// cross-fade between the "set" and "confirm" phases.
class _PinSection extends StatelessWidget {
  final String label;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  const _PinSection({
    super.key,
    required this.label,
    required this.hasError,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return PinKeypadField(
      label: label,
      length: kAdminPinLength,
      hasError: hasError,
      onChanged: onChanged,
      onCompleted: onCompleted,
    );
  }
}

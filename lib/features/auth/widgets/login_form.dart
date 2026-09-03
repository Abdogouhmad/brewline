import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/features/auth/providers/login_form_provider.dart';
import 'package:brewline/shared/widgets/shared/pin_keypad_field.dart';

/// The login form: PIN-only entry with auto-submit on completion.
///
/// No role selector, no username field — the system identifies the user
/// purely from the entered PIN. After 5 consecutive failures the keypad
/// locks for a 30-second cooldown with a visible countdown.
class LoginForm extends ConsumerWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Space.x2l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- PIN keypad ---
          PinKeypadField(
            label: 'Enter your PIN',
            length: kAdminPinLength,
            hasError: state.hasError,
            resetSignal: state.resetSignal,
            enabled: !state.isThrottled,
            onChanged: notifier.setPin,
            onCompleted: notifier.onPinCompleted,
          ),

          // --- Error / throttle message ---
          if (state.isThrottled) ...[
            SizedBox(height: Space.sm),
            Text(
              'Too many attempts. Try again in ${state.cooldownRemaining}s',
              style: TextStyle(color: colorScheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ] else if (state.submitError != null) ...[
            SizedBox(height: Space.sm),
            Text(
              state.submitError!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],

          SizedBox(height: Space.xl),

          // --- Submit (manual fallback — auto-submit fires on completion) ---
          FilledButton(
            onPressed: state.canSubmit
                ? () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    notifier.submit();
                  }
                : null,
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(
                responsiveValue(
                  context,
                  mobile: 52,
                  tablet: 60,
                  desktop: 64,
                ),
              ),
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
                    'Log in',
                    style: TextStyle(
                      fontSize: responsiveValue(
                        context,
                        mobile: 16,
                        desktop: 18,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

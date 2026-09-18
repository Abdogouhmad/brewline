import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/auth/providers/login_form_provider.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_inline_error.dart';
import 'package:brewline/shared/ui/ui_submit_button.dart';
import 'package:brewline/shared/widgets/pin_keypad_field.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final submitErrorText = switch (state.submitError) {
      null => null,
      LoginSubmitError.incorrectPin => l10n.loginIncorrectPin,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.x2l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- PIN keypad ---
          PinKeypadField(
            label: l10n.loginEnterPin,
            length: kAdminPinLength,
            hasError: state.hasError,
            resetSignal: state.resetSignal,
            enabled: !state.isThrottled,
            onChanged: notifier.setPin,
            onCompleted: notifier.onPinCompleted,
          ),

          // --- Error / throttle message ---
          if (state.isThrottled)
            UiInlineError(l10n.loginLockedOut(state.cooldownRemaining))
          else if (submitErrorText != null)
            UiInlineError(submitErrorText),

          const SizedBox(height: Space.xl),

          // --- Submit (manual fallback — auto-submit fires on completion) ---
          UiSubmitButton(
            l10n.loginButton,
            loading: state.isSubmitting,
            onPressed: state.canSubmit
                ? () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    notifier.submit();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

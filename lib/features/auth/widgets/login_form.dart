import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/auth/providers/login_form_provider.dart';
import 'package:brewline/shared/widgets/shared/app_text_field.dart';
import 'package:brewline/shared/widgets/shared/pin_keypad_field.dart';

/// The login form: username → PIN → submit.
///
/// Purely presentational — reads/writes [loginFormProvider] and submits through
/// it. The account's role (admin vs waiter) is auto-detected from the
/// username, so there is no role switch.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginFormProvider);
    final notifier = ref.read(loginFormProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Space.x2l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Username ---
          AppTextField(
            label: 'Username',
            hintText: 'Enter your username',
            controller: _usernameController,
            errorText: null,
            keyboardType: TextInputType.text,
            autofillHints: const [AutofillHints.username],
            onChanged: notifier.setUsername,
          ),
          SizedBox(height: Space.xl),

          // --- PIN keypad ---
          PinKeypadField(
            label: 'PIN',
            length: kAdminPinLength,
            hasError: state.hasError,
            resetSignal: state.resetSignal,
            onChanged: notifier.setPin,
            onCompleted: (_) {},
          ),
          if (state.submitError != null) ...[
            SizedBox(height: Space.sm),
            Text(
              state.submitError!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: Space.xl),

          // --- Submit ---
          FilledButton(
            onPressed: state.canSubmit && !state.isSubmitting
                ? () {
                    // Drop focus before submitting: the username field's
                    // blinking-cursor ticker would otherwise keep scheduling
                    // frames until pushReplacement disposes the page.
                    FocusManager.instance.primaryFocus?.unfocus();
                    notifier.submit();
                  }
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}

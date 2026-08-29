import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/auth/providers/login_form_provider.dart';
import 'package:brewline/shared/widgets/shared/app_text_field.dart';
import 'package:brewline/shared/widgets/shared/pin_keypad_field.dart';

import 'role_segmented_control.dart';

/// The login form: role switch → username → PIN → submit.
///
/// Purely presentational — reads/writes [loginFormProvider] and submits through
/// it. Switching roles swaps the contextual field labels in place without
/// navigating or clearing an already-entered username.
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

    final roleLabel = state.role.label;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Space.x2l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Role switch ---
          RoleSegmentedControl(
            selected: state.role,
            onChanged: (role) => notifier.setRole(role),
          ),
          SizedBox(height: Space.xl),

          // --- Username (contextual label, kept across role switches) ---
          AppTextField(
            label: '$roleLabel username',
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
            label: '$roleLabel PIN',
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
                ? () => notifier.submit()
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

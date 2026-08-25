import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Mock change-password form.
///
/// TODO: POST to the auth service once available; today it only validates
/// input and confirms with a snack bar.
Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  static const _minPasswordLength = 6;

  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    // The validator on each field guarantees a valid form here.
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop();
      showUiSnackBar(
        context,
        'Password updated successfully',
        type: UiSnackBarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lock_reset_rounded),
          SizedBox(width: Space.md),
          UiText('Change password', type: UiTextType.titleMedium),
        ],
      ),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentController,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Enter your current password' : null,
            ),
            SizedBox(height: Space.lg),
            TextFormField(
              controller: _newController,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) => (value == null || value.length < _minPasswordLength)
                  ? 'Use at least $_minPasswordLength characters'
                  : null,
            ),
            SizedBox(height: Space.lg),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              validator: (value) =>
                  value != _newController.text ? 'Passwords do not match' : null,
            ),
            SizedBox(height: Space.sm),
            // One eye toggle drives all three fields for brevity.
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                label: Text(_obscure ? 'Show' : 'Hide'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ),
        UiButton('Update', onPressed: _submit, variant: UiButtonVariant.filled),
      ],
    );
  }
}

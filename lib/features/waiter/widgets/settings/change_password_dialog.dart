import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/auth/pin_lookup.dart';
import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/credential_store.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/auth/providers/auth_state.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Opens the change-PIN form, bound to the signed-in session so it can verify
/// the current credential and persist the new one.
///
/// * **Admin** → verifies the current PIN against `admin_pin_hash` in
///   SharedPreferences and replaces it with the new hash.
/// * **Waiter** → verifies against their `staff` row and writes the new hash.
///
/// PIN uniqueness is enforced via `isPinTaken` before writing (§3.2).
Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _pinTakenError;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _pinTakenError = null;
    });

    final session = ref.read(authProvider).value;
    if (session == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showUiSnackBar(
        context,
        AppLocalizations.of(context)!.changePasswordNoSession,
        type: UiSnackBarType.error,
      );
      return;
    }

    final current = _currentController.text;
    final next = _newController.text;
    final l10n = AppLocalizations.of(context)!;
    final error = await _verifyCurrent(session, current, l10n);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
      });
      showUiSnackBar(context, error, type: UiSnackBarType.error);
      return;
    }

    // Enforce PIN uniqueness before persisting (§3.2).
    // Exclude the current user so their own unchanged PIN doesn't flag itself.
    final excludingId = session.role == Role.admin ? 'admin' : session.userId;
    final credentials = ref.read(credentialStoreProvider);
    final staffRepo = await ref.read(staffRepositoryProvider.future);
    final taken = await isPinTaken(
      next,
      excludingUserId: excludingId,
      credentials: credentials,
      staffRepo: staffRepo,
    );
    if (taken && mounted) {
      setState(() {
        _saving = false;
        _pinTakenError = AppLocalizations.of(context)!.changePasswordPinTaken;
      });
      return;
    }

    await _persistNew(session, next);
    if (mounted) {
      Navigator.of(context).pop();
      showUiSnackBar(
        context,
        AppLocalizations.of(context)!.changePasswordUpdated,
        type: UiSnackBarType.success,
      );
    }
  }

  /// `null` when the current PIN matches the store, otherwise a
  /// human-readable reason to surface (never reveals the stored hash).
  Future<String?> _verifyCurrent(
    AuthState session,
    String current,
    AppLocalizations l10n,
  ) async {
    if (session.role == Role.admin) {
      final admin = await ref.read(credentialStoreProvider).read();
      if (admin == null || admin.pinHash != hashPin(current, admin.pinSalt)) {
        return l10n.changePasswordWrongPin;
      }
      return null;
    }
    final repo = await ref.read(staffRepositoryProvider.future);
    final member = await repo.byUsername(session.username);
    if (member == null || member.pinHash != hashPin(current, member.pinSalt)) {
      return l10n.changePasswordWrongPin;
    }
    return null;
  }

  Future<void> _persistNew(AuthState session, String next) async {
    final salt = generateSalt();
    if (session.role == Role.admin) {
      final store = ref.read(credentialStoreProvider);
      final existing = await store.read();
      await store.write(
        AdminCredential(
          username: existing?.username ?? session.username,
          pinHash: hashPin(next, salt),
          pinSalt: salt,
        ),
      );
    } else {
      final repo = await ref.read(staffRepositoryProvider.future);
      final member = await repo.byUsername(session.username);
      if (member != null) {
        await repo.upsert(
          StaffMember(
            id: member.id,
            username: member.username,
            pinHash: hashPin(next, salt),
            pinSalt: salt,
            name: member.name,
            active: member.active,
            createdAt: member.createdAt,
          ),
        );
      }
    }
    // Record the change on the audit stream, like login/logout.
    final audit = await ref.read(auditRepositoryProvider.future);
    await audit.logEvent(
      eventType: 'password_changed',
      actor: session.username,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_reset_rounded),
          SizedBox(width: Space.md),
          UiText(l10n.changePasswordTitle, type: UiTextType.titleMedium),
        ],
      ),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                maxLength: kAdminPinLength,
                decoration: InputDecoration(
                  labelText: l10n.changePasswordCurrentPin,
                  counterText: '',
                ),
                validator: (value) => _requiredPin(context, value),
              ),
              SizedBox(height: Space.lg),
              TextFormField(
                controller: _newController,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                maxLength: kAdminPinLength,
                decoration: InputDecoration(
                  labelText: l10n.changePasswordNewPin,
                  counterText: '',
                  helperText: l10n.changePasswordNewPinHint,
                ),
                validator: (value) => _requiredPin(context, value),
              ),
              if (_pinTakenError != null) ...[
                SizedBox(height: Space.sm),
                Text(
                  _pinTakenError!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ],
              SizedBox(height: Space.lg),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                maxLength: kAdminPinLength,
                decoration: InputDecoration(
                  labelText: l10n.changePasswordConfirmPin,
                  counterText: '',
                ),
                validator: (value) => value != _newController.text
                    ? l10n.changePasswordMismatch
                    : _requiredPin(context, value),
              ),
              SizedBox(height: Space.sm),
              // One eye toggle drives all three fields for brevity.
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  label: Text(_obscure ? l10n.changePasswordShow : l10n.changePasswordHide),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.actionCancel,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        UiButton(
          _saving ? l10n.changePasswordUpdating : l10n.changePasswordUpdate,
          onPressed: _saving ? null : _submit,
          variant: UiButtonVariant.filled,
        ),
      ],
    );
  }

  String? _requiredPin(BuildContext context, String? value) {
    final text = value ?? '';
    if (text.length != kAdminPinLength) {
      return AppLocalizations.of(context)!.changePasswordPinLength(
        kAdminPinLength,
      );
    }
    return null;
  }
}

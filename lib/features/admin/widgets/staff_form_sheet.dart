import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/auth/pin_lookup.dart';
import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/credential_store.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/utils/id_generator.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_modal.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Opens the add / edit staff form as a bottom sheet on phones/tablets and a
/// dialog on desktop (see [showUiAdaptiveModal]).
///
/// [member] omitted → create mode (all fields shown); present → edit mode where
/// the PIN is optional (blank keeps the current one).
Future<void> showStaffFormSheet(BuildContext context, {StaffMember? member}) {
  return showUiAdaptiveModal<void>(
    context,
    heightFactor: 0.92,
    content: _StaffFormSheet(isEditing: member != null, member: member),
  );
}

/// Form backing the bottom sheet: display name, unique username, PIN
/// (create: required; edit: blank keeps the stored hash). Saves through
/// [StaffRepository] and bumps [staffMutationProvider] so the roster + shift
/// card refresh everywhere.
///
/// PIN uniqueness is enforced via `isPinTaken` before writing (§3.2).
class _StaffFormSheet extends ConsumerStatefulWidget {
  final bool isEditing;
  final StaffMember? member;

  const _StaffFormSheet({required this.isEditing, this.member});

  @override
  ConsumerState<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends ConsumerState<_StaffFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _pin;
  bool _obscurePin = true;
  bool _saving = false;
  String? _pinTakenError;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _name = TextEditingController(text: member?.name ?? '');
    _username = TextEditingController(text: member?.username ?? '');
    _pin = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _pinTakenError = null;
    });

    final repo = await ref.read(staffRepositoryProvider.future);
    final member = widget.member;
    final newPin = _pin.text;

    // Enforce PIN uniqueness before writing (§3.2).
    if (newPin.isNotEmpty) {
      final credentials = ref.read(credentialStoreProvider);
      final taken = await isPinTaken(
        newPin,
        excludingUserId: member?.id,
        credentials: credentials,
        staffRepo: repo,
      );
      if (taken && mounted) {
        setState(() {
          _saving = false;
          _pinTakenError = AppLocalizations.of(context)!.changePasswordPinTaken;
        });
        return;
      }
    }

    // A fresh per-user salt is generated whenever the PIN is set or changed
    // (never reused, even when two accounts pick the same PIN).
    final salt = newPin.isNotEmpty ? generateSalt() : null;

    final updated = StaffMember(
      id: member?.id ?? generatePrefixedId('staff'),
      username: _username.text.trim(),
      pinHash: newPin.isNotEmpty ? hashPin(newPin, salt) : member!.pinHash,
      pinSalt: newPin.isNotEmpty ? salt : member?.pinSalt,
      name: _name.text.trim(),
      active: member?.active ?? true,
      createdAt: member?.createdAt ?? DateTime.now(),
    );

    await repo.upsert(updated);
    ref.read(staffMutationProvider.notifier).bump();

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    showUiSnackBar(
      context,
      widget.isEditing
          ? l10n.staffFormUpdatedSnackbar(updated.name)
          : l10n.staffFormAddedSnackbar(updated.name),
      type: UiSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: adaptiveModalPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    widget.isEditing
                        ? Icons.edit_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: Space.md),
                  UiText(
                    widget.isEditing
                        ? l10n.staffFormEditTitle
                        : l10n.staffFormAddTitle,
                    type: UiTextType.titleLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              SizedBox(height: Space.xl),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.staffFormName,
                  helperText: l10n.staffFormNameHint,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.staffFormNameRequired
                    : null,
              ),
              SizedBox(height: Space.lg),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: l10n.staffFormUsername,
                  helperText: l10n.staffFormUsernameHint,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return l10n.staffFormUsernameRequired;
                  if (text.length < 3) return l10n.staffFormUsernameTooShort;
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
                    return l10n.staffFormUsernameInvalid;
                  }
                  return null;
                },
              ),
              SizedBox(height: Space.lg),
              TextFormField(
                controller: _pin,
                keyboardType: TextInputType.number,
                obscureText: _obscurePin,
                maxLength: kAdminPinLength,
                decoration: InputDecoration(
                  labelText: widget.isEditing
                      ? l10n.staffFormNewPin
                      : l10n.staffFormPin,
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePin
                        ? l10n.changePasswordShow
                        : l10n.changePasswordHide,
                    icon: Icon(
                      _obscurePin
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  ),
                ),
                validator: (value) {
                  final text = value ?? '';
                  if (widget.isEditing && text.isEmpty) return null;
                  if (text.length != kAdminPinLength) {
                    return l10n.staffFormErrorPinLength(kAdminPinLength);
                  }
                  return null;
                },
              ),
              if (_pinTakenError != null) ...[
                SizedBox(height: Space.sm),
                UiText(
                  _pinTakenError!,
                  type: UiTextType.bodySmall,
                  color: colorScheme.error,
                ),
              ],
              SizedBox(height: Space.sm),
              if (widget.isEditing)
                UiText(
                  l10n.staffFormEditNote,
                  type: UiTextType.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              SizedBox(height: Space.xl),
              UiButton(
                _saving
                    ? l10n.staffFormSaving
                    : (widget.isEditing
                          ? l10n.staffFormSaveChanges
                          : l10n.staffFormAddMember),
                icon: Icons.check_rounded,
                variant: UiButtonVariant.filled,
                expand: true,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

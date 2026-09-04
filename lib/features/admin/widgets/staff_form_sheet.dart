import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/auth/pin_lookup.dart';
import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/password_hash.dart';
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
      final taken = await ref.read(isPinTakenProvider)(
        newPin,
        excludingUserId: member?.id,
      );
      if (taken && mounted) {
        setState(() {
          _saving = false;
          _pinTakenError = 'That PIN is already in use — pick a different one';
        });
        return;
      }
    }

    final updated = StaffMember(
      id: member?.id ?? 'staff-${DateTime.now().millisecondsSinceEpoch}',
      username: _username.text.trim(),
      pinHash: newPin.isEmpty
          ? (member?.pinHash ?? hashPin(newPin))
          : hashPin(newPin),
      name: _name.text.trim(),
      active: member?.active ?? true,
      createdAt: member?.createdAt ?? DateTime.now(),
    );

    await repo.upsert(updated);
    ref.read(staffMutationProvider.notifier).bump();

    if (!mounted) return;
    Navigator.of(context).pop();
    showUiSnackBar(
      context,
      widget.isEditing
          ? '${updated.name} updated'
          : '${updated.name} added to staff',
      type: UiSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                    widget.isEditing ? 'Edit staff member' : 'Add staff member',
                    type: UiTextType.titleLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              SizedBox(height: Space.xl),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  helperText: 'Shown on shift and performance views',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a display name'
                    : null,
              ),
              SizedBox(height: Space.lg),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  helperText: 'Used to sign in on the POS',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Enter a username';
                  if (text.length < 3) return 'At least 3 characters';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
                    return 'Letters, numbers and underscores only';
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
                      ? 'New PIN (blank keeps current)'
                      : 'PIN',
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin_rounded),
                  suffixIcon: IconButton(
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
                    return 'Use exactly $kAdminPinLength digits';
                  }
                  return null;
                },
              ),
              if (_pinTakenError != null) ...[
                SizedBox(height: Space.sm),
                Text(
                  _pinTakenError!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ],
              SizedBox(height: Space.sm),
              if (widget.isEditing)
                Text(
                  'Account stays active. Deactivate instead to block sign-in.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              SizedBox(height: Space.xl),
              UiButton(
                _saving
                    ? 'Saving…'
                    : (widget.isEditing ? 'Save changes' : 'Add member'),
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

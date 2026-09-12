/// Destructive-action confirmation for a database restore.
///
/// Restoring is the single most destructive action in the app — more so than a
/// refund or a void, both of which are scoped to one order. A restore
/// replaces *everything* since the backup's snapshot was taken, so this dialog
/// deliberately demands **more than a single tap**: the admin sees the backup's
/// version/date/device and must re-enter their admin PIN before the "Restore"
/// button is ever enabled (§4.3 of the backup spec).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/auth/pin_lookup.dart';
import 'package:brewline/core/backup/backup_archive.dart';
import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/credential_store.dart';
import 'package:brewline/core/utils/date_format.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Returns `true` only after the admin verified their own PIN.
Future<bool> showRestoreConfirmDialog(
  BuildContext context,
  BackupManifest manifest,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => RestoreConfirmDialog(manifest: manifest),
  );
  return result ?? false;
}

class RestoreConfirmDialog extends ConsumerStatefulWidget {
  final BackupManifest manifest;

  const RestoreConfirmDialog({super.key, required this.manifest});

  @override
  ConsumerState<RestoreConfirmDialog> createState() =>
      _RestoreConfirmDialogState();
}

class _RestoreConfirmDialogState extends ConsumerState<RestoreConfirmDialog> {
  final _pinController = TextEditingController();
  bool _verifying = false;
  bool _wrongPin = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  /// Verifies the entered PIN against the signed-in admin account before
  /// popping `true`. A wrong PIN just re-arms the field — nothing is restored.
  Future<void> _verifyAndConfirm() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;
    setState(() {
      _verifying = true;
      _wrongPin = false;
    });

    final credentials = ref.read(credentialStoreProvider);
    final staffRepo = await ref.read(staffRepositoryProvider.future);
    final result = await findUserByPin(
      pin,
      credentials: credentials,
      staffRepo: staffRepo,
    );

    if (!mounted) return;
    if (result == null || result.role != Role.admin) {
      _pinController.clear();
      setState(() {
        _verifying = false;
        _wrongPin = true;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final manifest = widget.manifest;

    return AlertDialog(
      title: UiText(
        l10n.backupRestoreConfirmTitle,
        type: UiTextType.titleMedium,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiText(
                l10n.backupRestoreConfirmBody,
                type: UiTextType.bodyMedium,
              ),
              SizedBox(height: Space.lg),
              // The backup's identity so the admin has context before
              // committing — version + date carry meaning, and the device
              // label disambiguates between several backup files.
              Container(
                padding: EdgeInsets.all(Space.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Rounded.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetaRow(
                      label: l10n.updateCurrentVersion,
                      value: 'v${manifest.appVersion}',
                    ),
                    SizedBox(height: Space.xs),
                    _MetaRow(
                      label: l10n.updateLastChecked,
                      value: formatDateWithTime(manifest.createdAt.toLocal()),
                    ),
                    if (manifest.deviceLabel != null) ...[
                      SizedBox(height: Space.xs),
                      _MetaRow(label: l10n.backupDeviceLabelTitle, value: manifest.deviceLabel!),
                    ],
                  ],
                ),
              ),
              SizedBox(height: Space.lg),
              if (manifest.schemaVersion < kDatabaseSchemaVersion)
                Container(
                  padding: EdgeInsets.all(Space.lg),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(Rounded.lg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.update_rounded,
                        size: AppSizes.iconMd,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      SizedBox(width: Space.sm),
                      Expanded(
                        child: UiText(
                          l10n.backupSchemaOlderWarning,
                          type: UiTextType.bodySmall,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: Space.lg),
              TextField(
                controller: _pinController,
                obscureText: true,
                readOnly: _verifying,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_verifying,
                onChanged: (_) => setState(() => _wrongPin = false),
                decoration: InputDecoration(
                  labelText: l10n.backupRestoreConfirmFieldLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.pin_rounded),
                  errorText: _wrongPin ? l10n.backupWrongPin : null,
                ),
                onSubmitted: (_) {
                  if (_pinController.text.isNotEmpty) _verifyAndConfirm();
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _verifying ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        UiButton(
          _verifying ? l10n.backupRestoring : l10n.backupConfirmRestore,
          variant: UiButtonVariant.destructive,
          onPressed:
              _verifying || _pinController.text.isEmpty ? null : _verifyAndConfirm,
        ),
      ],
    );
  }
}

/// One label:value line inside the manifest summary box.
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          label,
          type: UiTextType.bodySmall,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: Space.md),
        Flexible(
          child: UiText(
            value,
            type: UiTextType.bodySmall,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
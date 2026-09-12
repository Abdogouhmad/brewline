/// Settings **Data** section — the admin-only entry point for backup & restore.
///
/// * **Create backup** — packs the live database (via `VACUUM INTO`), the
///   preferences and the product images into one `.brewline` archive, then
///   hands it off *off-device*: a native save/sharesheet dialog on Android/iOS
///   (`share_plus`), or the OS file-save dialog defaulting to Downloads on
///   Windows/Linux (`file_selector`).
/// * **Restore from file** — picks a `.brewline` archive, strictly validates
///   its manifest (a backup from a newer app version is rejected before
///   anything is touched), shows the backup's origin + date, and only after
///   the admin re-enters their PIN restores it onto the device — a
///   pre-restore safety snapshot is written first (§3 & §4 of the backup spec).
///
/// After a successful restore the whole app restarts **in-process**
/// ([appRestartProvider]) so every provider reconnects to the swapped
/// database; the service deliberately does not hot-swap the live connection.
library;

import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:brewline/core/app_restart.dart';
import 'package:brewline/core/backup/backup_archive.dart';
import 'package:brewline/core/backup/backup_service.dart';
import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/features/admin/providers/backup_provider.dart';
import 'package:brewline/features/admin/widgets/settings/restore_confirm_dialog.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/shared/widgets/settings/settings_section_card.dart';
import 'package:brewline/shared/widgets/settings/settings_tile.dart';

class DataSection extends ConsumerWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lastBackup = ref.watch(lastBackupAtProvider);
    final deviceLabel = ref.watch(deviceLabelProvider);

    return SettingsSectionCard(
      titleHeader: l10n.backupDataSectionTitle,
      icon: Icons.backup_rounded,
      title: l10n.backupSectionTitle,
      subtitle: l10n.backupSectionSubtitle,
      children: [
        SettingsTile(
          icon: Icons.save_alt_rounded,
          title: l10n.backupCreateButtonLabel,
          subtitle: _lastBackupLabel(context, lastBackup),
          onTap: () => _createBackup(context, ref),
        ),
        SettingsTile(
          icon: Icons.restore_rounded,
          title: l10n.backupRestoreButtonLabel,
          subtitle: (deviceLabel.isEmpty) ? null : deviceLabel,
          destructive: true,
          onTap: () => _restore(context, ref),
        ),
        SettingsTile(
          icon: Icons.badge_outlined,
          title: l10n.backupDeviceLabelTitle,
          subtitle: l10n.backupDeviceLabelSubtitle,
          trailing: deviceLabel.isEmpty
              ? null
              : UiText(
                  deviceLabel,
                  type: UiTextType.labelMedium,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          onTap: () => _editDeviceLabel(context, ref),
        ),
      ],
    );
  }

  /// "Never backed up" / "Last backup: today" / "Last backup: {count} days
  /// ago", from the persisted [lastBackupAtProvider].
  String _lastBackupLabel(BuildContext context, DateTime? lastBackup) {
    final l10n = AppLocalizations.of(context)!;
    if (lastBackup == null) return l10n.backupLastBackupLabel(0);
    final days = DateTime.now().difference(lastBackup).inDays;
    if (days <= 0) return l10n.backupLastBackupToday;
    return l10n.backupLastBackupLabel(days);
  }

  /// Creates a `.brewline` archive and hands it off off-device: share sheet on
  /// mobile, OS save dialog (defaulting to Downloads) on desktop. The persisted
  /// "last backup" timestamp only advances when the hand-off actually
  /// completed — a dismissed share sheet or cancelled save dialog leaves it
  /// unchanged, since no backup file exists anywhere.
  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final service = await ref.read(backupServiceProvider.future);

    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final outputDir = isMobile
        ? await getTemporaryDirectory()
        : (await getDownloadsDirectory()) ?? await getTemporaryDirectory();
    final suggestedName =
        'brewline-backup-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.$kBackupExtension';
    final outputPath = p.join(outputDir.path, suggestedName);

    if (!context.mounted) return;

    try {
      await _withProgress(
        context,
        barrierDismissible: !isMobile,
        builder: (_) => _ProgressDialog(message: l10n.backupCreateInProgress),
        action: () async {
          await service.create(
            outputPath: outputPath,
            actor: ref.read(authProvider).value?.username ?? 'admin',
          );
        },
      );

      if (!context.mounted) return;

      var handedOff = isMobile;
      if (isMobile) {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(outputPath, mimeType: 'application/zip', name: suggestedName)],
            subject: suggestedName,
          ),
        );
        handedOff = result.status != ShareResultStatus.dismissed;
      } else {
        final location = await getSaveLocation(
          suggestedName: suggestedName,
          acceptedTypeGroups: const [
            XTypeGroup(extensions: [kBackupExtension], mimeTypes: ['application/zip']),
          ],
        );
        if (location != null) {
          await File(outputPath).copy(location.path);
        } else {
          handedOff = false;
        }
      }

      if (context.mounted && handedOff) {
        await ref.read(lastBackupAtProvider.notifier).markBackedUp(DateTime.now());
        if (context.mounted) {
          showUiSnackBar(context, l10n.backupCreateSuccess,
              type: UiSnackBarType.success);
        }
      }
    } catch (_) {
      if (context.mounted) {
        showUiSnackBar(context, l10n.backupCreateError,
            type: UiSnackBarType.error);
      }
    } finally {
      final temp = File(outputPath);
      if (await temp.exists()) await temp.delete();
    }
  }

  /// Picks a `.brewline` archive, strictly validates its manifest, shows the
  /// backup's origin + date + PIN gate ([RestoreConfirmDialog]) and only then
  /// restores. A newer-schema backup is rejected before any file is touched.
  ///
  /// Every step below is real device/OS async work that can throw; without a
  /// catch each failure mode silently "did nothing" from the admin's point of
  /// view. Each phase surfaces its own error snack bar instead.
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    Future<void> fail(String message) async {
      if (context.mounted) {
        showUiSnackBar(context, message, type: UiSnackBarType.error);
      }
    }

    final BackupService service;
    final BackupManifest manifest;
    XFile? location;
    try {
      // The service starts from the live database + documents directory, both
      // of which can fail independently of the archive being restored.
      service = await ref.read(backupServiceProvider.future);
      location = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(extensions: [kBackupExtension]),
        ],
      );
      if (location == null || !context.mounted) return;
      manifest = await service.validateManifest(File(location.path));
    } on BackupSchemaTooNewException {
      await fail(l10n.backupSchemaTooNewError);
      return;
    } catch (_) {
      await fail(l10n.backupInvalidFileError);
      return;
    }

    if (!context.mounted) return;

    final bool confirmed;
    try {
      confirmed = await showRestoreConfirmDialog(context, manifest);
    } catch (_) {
      await fail(l10n.backupFailed);
      return;
    }
    if (!confirmed || !context.mounted) return;

    final dbHandle = ref.read(appDatabaseHandleProvider);
    try {
      await _withProgress(
        context,
        barrierDismissible: false,
        builder: (_) => _ProgressDialog(message: l10n.backupRestoring),
        action: () async {
          await service.restore(
            archiveFile: File(location!.path),
            dbHandle: dbHandle,
            actor: ref.read(authProvider).value?.username ?? 'admin',
          );
        },
      );
    } catch (_) {
      // [_withProgress] already closed the progress dialog so the failure can
      // be surfaced. The pre-restore safety snapshot means current data is
      // still intact and undoable.
      await fail(l10n.backupFailed);
      return;
    }

    if (!context.mounted) return;
    // Restore succeeded and the progress dialog is gone. Rebuild the whole app
    // against the swapped database: the fresh provider tree starts logged out,
    // so the admin lands on the login screen signed in as the restored
    // credential.
    await ref.read(appRestartProvider)();
  }

  Future<void> _editDeviceLabel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        TextEditingController(text: ref.read(deviceLabelProvider));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: UiText(l10n.backupDeviceLabelTitle, type: UiTextType.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(
            helperText: l10n.backupDeviceLabelSubtitle,
            hintText: l10n.backupDeviceLabelHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.backupDeviceLabelSave),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await ref.read(deviceLabelProvider.notifier).setLabel(result);
    }
  }
}

/// Runs [action] while a non-dismissible progress dialog is on screen, closing
/// the dialog first on failure so the error can be surfaced via a snack bar.
Future<void> _withProgress(
  BuildContext context, {
  required bool barrierDismissible,
  required WidgetBuilder builder,
  required Future<void> Function() action,
}) async {
  if (!context.mounted) return;
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    ),
  );
  try {
    await action();
  } finally {
    // The dialog may have been popped already (successful restore restarts the
    // app); popping again is a no-op returned as false.
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class _ProgressDialog extends StatelessWidget {
  final String message;

  const _ProgressDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          SizedBox(width: Space.lg),
          Expanded(
            child: UiText(message, type: UiTextType.bodyMedium),
          ),
        ],
      ),
    );
  }
}
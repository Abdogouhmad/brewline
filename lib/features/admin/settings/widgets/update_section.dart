import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/features/admin/settings/widgets/update_action_sheet.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_section_card.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_tile.dart';

/// Human-readable label for the current platform, shown next to the version
/// so an admin can tell whether they're looking at the phone or the
/// front-counter desktop build at a glance.
String currentPlatformLabel() {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isWindows) return 'Windows';
  if (Platform.isLinux) return 'Linux';
  return Platform.operatingSystem;
}

/// Settings card for OTA updates: current version + platform, a "Check for
/// updates" action, an auto-check toggle and a status line driven by
/// [updateProvider].
class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final appInfo = ref.watch(appInfoProvider);
    final updater = ref.watch(updateProvider);
    final autoCheck = ref.watch(autoCheckUpdatesProvider);
    final lastChecked = ref.watch(lastUpdateCheckProvider);

    final versionLabel = appInfo.maybeWhen(
      data: (info) => '${info.version} (${currentPlatformLabel()})',
      orElse: () => '…',
    );

    final statusText = switch (updater.status) {
      UpdateStatus.checking => 'Checking for updates…',
      UpdateStatus.available when updater.hasUpdate => updater.isMandatory
          ? 'A mandatory update is available'
          : 'An update is available',
      UpdateStatus.downloading => 'Downloading…',
      UpdateStatus.readyToInstall => 'Ready to install',
      UpdateStatus.error => 'Update check failed',
      _ => 'Up to date',
    };

    final lastCheckedText = lastChecked == null
        ? 'Never checked'
        : 'Last checked ${_friendlyTime(lastChecked)}';

    return SettingsSectionCard(
      icon: Icons.system_update_alt_rounded,
      title: 'Update',
      subtitle: 'Keep this terminal on the latest version',
      accent: SettingsAccent.secondary,
      children: [
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'Version',
          subtitle: '$versionLabel · $lastCheckedText',
          onTap: () => showUpdateActionSheet(context),
        ),
        SettingsTile(
          icon: Icons.cloud_sync_outlined,
          title: updater.status == UpdateStatus.checking
              ? 'Checking…'
              : 'Check for updates',
          subtitle: statusText,
          trailing: updater.status == UpdateStatus.checking
              ? const SizedBox(
                  width: AppSizes.iconMd,
                  height: AppSizes.iconMd,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.system_update_alt_rounded,
                  color: colorScheme.primary,
                ),
          onTap: updater.status == UpdateStatus.checking
              ? null
              : () {
                  ref.read(updateProvider.notifier).checkForUpdates();
                  showUpdateActionSheet(context);
                },
        ),
        SettingsTile(
          icon: Icons.autorenew_rounded,
          title: 'Check automatically',
          subtitle: 'Look for updates when the app starts',
          trailing: Switch(
            value: autoCheck,
            onChanged: (value) =>
                ref.read(autoCheckUpdatesProvider.notifier).setEnabled(value),
          ),
        ),
      ],
    );
  }

  /// Compact relative/"HH:MM" label for the last-checked timestamp.
  static String _friendlyTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${t.day}/${t.month}';
  }
}

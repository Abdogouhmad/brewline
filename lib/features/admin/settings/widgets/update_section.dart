import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/features/admin/settings/widgets/update_screen.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_section_card.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_tile.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Settings card for OTA updates. It's the **entry point** to the dedicated
/// [UpdateScreen] (pushed as a nested route on both admin and waiter pages),
/// and also carries the auto-check toggle so it stays available without
/// leaving Settings.
///
/// Tapping the summary tile opens the full update center: status header,
/// version details, changelog and the download/install action.
class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final appInfo = ref.watch(appInfoProvider);
    final updater = ref.watch(updateProvider);
    final autoCheck = ref.watch(autoCheckUpdatesProvider);

    final versionLabel = appInfo.maybeWhen(
      data: (info) => 'v${info.version}',
      orElse: () => '…',
    );

    return SettingsSectionCard(
      icon: Icons.system_update_alt_rounded,
      title: 'Update',
      subtitle: 'Keep this terminal on the latest version',
      accent: SettingsAccent.secondary,
      children: [
        SettingsTile(
          icon: Icons.system_update_alt_rounded,
          title: 'Software update',
          subtitle: _summaryText(updater),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UiText(
                versionLabel,
                type: UiTextType.labelMedium,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: Space.lg),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UpdateScreen()),
          ),
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

  /// One-line summary of the current update state for the entry tile.
  static String _summaryText(UpdateState updater) {
    return switch (updater.status) {
      UpdateStatus.checking => 'Checking for updates…',
      UpdateStatus.available when updater.hasUpdate => updater.isMandatory
          ? 'Update required'
          : 'An update is available',
      UpdateStatus.downloading => 'Downloading…',
      UpdateStatus.readyToInstall => 'Ready to install',
      UpdateStatus.error => 'Update check failed',
      _ => 'Up to date',
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/update_installer.dart' show UpdateCheckResult;
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/features/admin/widgets/settings/update_screen.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/widgets/settings/settings_section_card.dart';
import 'package:brewline/shared/widgets/settings/settings_tile.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Settings card for OTA updates. It's the **entry point** to the dedicated
/// [UpdateScreen] (pushed as a nested route on both admin and waiter pages).
///
/// Tapping the summary tile opens the full update center: status header,
/// version details, changelog and the download/install action. The auto-check
/// toggle lives inside that screen, not here.
class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final appInfo = ref.watch(appInfoProvider);
    final updater = ref.watch(updateProvider);
    final l10n = AppLocalizations.of(context)!;

    final versionLabel = appInfo.maybeWhen(
      data: (info) => 'v${info.version}',
      orElse: () => '…',
    );

    return SettingsSectionCard(
      titleHeader: l10n.updateSectionSystem,
      icon: Icons.system_update_alt_rounded,
      title: l10n.updateSectionTitle,
      subtitle: l10n.updateSectionSubtitle,
      accent: SettingsAccent.secondary,
      children: [
        SettingsTile(
          icon: Icons.system_update_alt_rounded,
          title: l10n.updateSoftwareUpdate,
          subtitle: _summaryText(updater, l10n),
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
      ],
    );
  }

  /// One-line summary of the current update state for the entry tile.
  static String _summaryText(UpdateState updater, AppLocalizations l10n) {
    // A failed background check leaves `status` idle with `checkResult`
    // checkFailed — surface it instead of a misleading "Up to date".
    if (updater.checkResult == UpdateCheckResult.checkFailed &&
        updater.status == UpdateStatus.idle) {
      return l10n.updateCheckFailedPill;
    }
    return switch (updater.status) {
      UpdateStatus.checking => l10n.updateCheckingPill,
      UpdateStatus.available when updater.hasUpdate => updater.isMandatory
          ? l10n.updateResultMandatory
          : l10n.updateSummaryAvailable,
      UpdateStatus.downloading => l10n.updateSummaryDownloading,
      UpdateStatus.readyToInstall => l10n.updateSummaryReady,
      UpdateStatus.error => l10n.updateCheckFailedPill,
      _ => l10n.updateResultUpToDate,
    };
  }
}

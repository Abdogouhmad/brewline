import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/theme/app_theme.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Small settings footer: brand + version line that doubles as a button
/// opening the detailed app-info sheet.
class SettingsFooter extends ConsumerWidget {
  const SettingsFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final appInfo = ref.watch(appInfoProvider);

    final versionLabel = appInfo.maybeWhen(
      data: (info) => 'v${info.version} (${info.buildNumber})',
      orElse: () => '…',
    );

    return Column(
      children: [
        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        SizedBox(height: Space.lg),
        InkWell(
          onTap: () => showAppInfoSheet(context),
          borderRadius: BorderRadius.circular(Rounded.md),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_cafe_rounded,
                    size: AppSizes.iconSm + 4, color: colorScheme.primary),
                SizedBox(width: Space.sm),
                Flexible(
                  child: UiText(
                    'BrewLine',
                    type: UiTextType.labelLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: Space.sm),
                UiText(
                  versionLabel,
                  type: UiTextType.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        UiText(
          '© ${DateTime.now().year} BrewLine',
          type: UiTextType.bodySmall,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

void showAppInfoSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => const _AppInfoSheet(),
  );
}

class _AppInfoSheet extends ConsumerWidget {
  const _AppInfoSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appInfoProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.local_cafe_rounded,
              size: AppSizes.iconLg + 16,
              color: kSeedColor,
            ),
            SizedBox(height: Space.sm),
            const Center(
              child: UiText(
                'BrewLine',
                type: UiTextType.headlineSmall,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: Space.xl),
            info.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  UiText('Could not load app info', color: colorScheme.error),
              data: (i) => Column(
                children: [
                  _infoRow(context, 'Name', i.appName),
                  _infoRow(context, 'Version', i.version),
                  _infoRow(context, 'Build', i.buildNumber),
                  _infoRow(context, 'Package', i.packageName),
                ],
              ),
            ),
            SizedBox(height: Space.xl),
            OutlinedButton.icon(
              onPressed: () =>
                  showLicensePage(context: context, applicationName: 'BrewLine'),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Open source licenses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: Space.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UiText(
            label,
            type: UiTextType.bodyMedium,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          UiText(value, type: UiTextType.titleSmall, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}

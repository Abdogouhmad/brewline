import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/theme/app_theme.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/shared/providers/user_provider.dart';
import 'package:brewline/shared/ui/ui_list.dart';
import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/shared/widgets/profile_chip.dart';

/// Settings content — Preferences (theme), Account, About.
/// Title lives in the [AppShell] app bar (or the standalone wrapper in
/// [WaiterAppBarActions]); no local app bar to avoid a duplicated title.
/// Content width is capped on desktop so it stays readable.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePref = ref.watch(themeControllerProvider);
    final appInfo = ref.watch(appInfoProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: responsivePadding(context),
            vertical: Space.lg,
          ),
          children: [
            const ProfileChip(),
            SizedBox(height: Space.x2l),

            /// 🔹 PREFERENCES
            UiListSection(
              title: 'Preferences',
              children: [
                UiListGroup(
                  header: 'Appearance',
                  footer: 'Follows the system theme by default.',
                  children: [ThemeToggler(current: themePref)],
                ),
              ],
            ),

            /// 🔹 ACCOUNT
            UiListSection(
              title: 'Account',
              children: [
                const UiListGroup(useCard: false, children: [_AccountTile()]),
              ],
            ),

            /// 🔹 ABOUT
            UiListSection(
              title: 'About',
              children: [
                UiListGroup(
                  useCard: false,
                  children: [
                    AppInfoTile(appInfo: appInfo),
                    const Divider(height: 1, indent: Space.xl),
                    const _LicenseTile(),
                  ],
                ),
              ],
            ),
            SizedBox(height: Space.x2l),
          ],
        ),
      ),
    );
  }
}

double responsivePadding(BuildContext context) =>
    MediaQuery.of(context).size.width < 600 ? Space.lg : Space.full;

/// Modern segmented theme selector: system / light / dark with icons.
class ThemeToggler extends ConsumerWidget {
  final ThemePref current;

  const ThemeToggler({super.key, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(Space.md),
      child: SegmentedButton<ThemePref>(
        selected: {current},
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: Theme.of(context)
              .colorScheme
              .secondaryContainer,
          selectedForegroundColor: Theme.of(context)
              .colorScheme
              .onSecondaryContainer,
        ),
        segments: const [
          ButtonSegment(
            value: ThemePref.system,
            icon: Icon(Icons.brightness_auto_rounded),
            label: Text('System'),
          ),
          ButtonSegment(
            value: ThemePref.light,
            icon: Icon(Icons.light_mode_rounded),
            label: Text('Light'),
          ),
          ButtonSegment(
            value: ThemePref.dark,
            icon: Icon(Icons.dark_mode_rounded),
            label: Text('Dark'),
          ),
        ],
        onSelectionChanged: (selection) => ref
            .read(themeControllerProvider.notifier)
            .setTheme(selection.first),
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return UiListTile(
      leading: const UiListAvatar(icon: Icons.person_rounded),
      title: user.name,
      subtitle: user.role,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}

class AppInfoTile extends StatelessWidget {
  final AsyncValue<AppInfoData> appInfo;

  const AppInfoTile({super.key, required this.appInfo});

  @override
  Widget build(BuildContext context) {
    final subtitle = appInfo.maybeWhen(
      data: (info) =>
          '${info.appName} · v${info.version} (${info.buildNumber})',
      orElse: () => 'BrewLine',
    );

    return UiListTile(
      leading: const UiListAvatar(icon: Icons.info_outline_rounded),
      title: 'App info',
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => showAppInfoSheet(context),
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
            UiText(
              '© ${DateTime.now().year} BrewLine. All rights reserved.',
              type: UiTextType.bodySmall,
              color: colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
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
          UiText(
            value,
            type: UiTextType.titleSmall,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

const Color kSeedFallback = Color(0xFF6F4E37);

class _LicenseTile extends StatelessWidget {
  const _LicenseTile();

  @override
  Widget build(BuildContext context) {
    return UiListTile(
      leading: const UiListAvatar(icon: Icons.description_outlined),
      title: 'Licenses',
      subtitle: 'Open source licenses',
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () =>
          showLicensePage(context: context, applicationName: 'BrewLine'),
    );
  }
}

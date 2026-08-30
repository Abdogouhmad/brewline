import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/admin/settings/widgets/printer_settings_section.dart';
import 'package:brewline/features/onboarding/pages/onboarding_page.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/features/waiter/widgets/settings/change_password_dialog.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_footer.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_section_card.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_tile.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/shared/widgets/settings/language_dropdown.dart';
import 'package:brewline/shared/widgets/settings/theme_segmented_control.dart';
import 'package:brewline/widgets/shared/logout_button.dart';

/// Admin "Settings" tab.
///
/// Redesigned around the same `SettingsSectionCard` vocabulary as the waiter
/// page: a hero profile header showing the signed-in account, a **General**
/// card (language + theme) and an **Account** card that shows the admin
/// username and offers change PIN, logout and the destructive reset — wiping
/// the business database and returning to onboarding.
class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageControllerProvider);
    final themePref = ref.watch(themeControllerProvider);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 600
            ? Space.lg
            : Space.full,
        vertical: Space.lg,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth / 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProfileHeader(),
                SizedBox(height: Space.x2l),
                SettingsSectionCard(
                  icon: Icons.tune_rounded,
                  title: 'General',
                  subtitle: 'Language and appearance',
                  children: [
                    SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'Interface language for this device',
                      trailing: LanguageDropdown(
                        value: language,
                        onChanged: (value) => ref
                            .read(languageControllerProvider.notifier)
                            .setLanguage(value),
                      ),
                    ),
                    ThemeSegmentedControl(
                      themePref: themePref,
                      onChanged: (value) => ref
                          .read(themeControllerProvider.notifier)
                          .setTheme(value),
                    ),
                  ],
                ),
                SizedBox(height: Space.lg),
                const PrinterSettingsSection(),
                SizedBox(height: Space.lg),
                _AccountCard(onReset: () => _confirmReset(context, ref)),
                SizedBox(height: Space.lg),
                const SettingsFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const UiText(
          'Reset business data?',
          type: UiTextType.titleMedium,
        ),
        content: const UiText(
          'This deletes the admin account and all business data (orders, '
          'staff, products) and returns you to the setup screen.',
          type: UiTextType.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          UiButton(
            'Reset',
            variant: UiButtonVariant.filled,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final prefs = ref.read(sharedPreferencesProvider);
    // Clear the onboarding flag AND the stored credentials the login screen
    // validates against, so a fresh setup starts from a clean slate.
    await prefs.remove(kOnboardingCompleteKey);
    await prefs.remove(kAdminUsernameKey);
    await prefs.remove(kAdminPinHashKey);
    await deleteAllData(await ref.read(appDatabaseProvider.future));
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(onboardingCompleteProvider);

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (_) => false,
      );
    }
  }
}

/// Hero card: avatar + the signed-in admin's username + role badge.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value;
    final colorScheme = Theme.of(context).colorScheme;
    final username = session?.username ?? '…';
    final role = session?.role.label ?? 'Admin';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.x2l),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(Space.xl),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: UiText(
                _initials(username),
                type: UiTextType.titleLarge,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    username,
                    type: UiTextType.headlineSmall,
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: Space.sm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Badge(colorScheme: colorScheme, label: role),
                      SizedBox(width: Space.md),
                      Icon(
                        Icons.schedule_rounded,
                        size: AppSizes.iconSm + 2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: Space.xs),
                      UiText(
                        'On shift',
                        type: UiTextType.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String username) {
    if (username.isEmpty || username == '…') return 'A';
    return username[0].toUpperCase();
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _Badge({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: UiText(
        label,
        type: UiTextType.labelMedium,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }
}

/// Account section: the signed-in credential, change PIN, logout and the
/// destructive database reset.
class _AccountCard extends ConsumerWidget {
  final VoidCallback onReset;

  const _AccountCard({required this.onReset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(authProvider).value?.username ?? '…';

    return SettingsSectionCard(
      icon: Icons.person_rounded,
      title: 'Account',
      subtitle: 'Your sign-in and session',
      accent: SettingsAccent.tertiary,
      children: [
        SettingsTile(
          icon: Icons.badge_outlined,
          title: 'Signed in as',
          subtitle: username,
          trailing: UiText(
            'Administrator',
            type: UiTextType.labelMedium,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        SettingsTile(
          icon: Icons.lock_reset_rounded,
          title: 'Change password',
          subtitle: 'Update your login credentials',
          onTap: () => showChangePasswordDialog(context),
        ),
        SettingsTile(
          icon: Icons.logout_rounded,
          title: 'Log out',
          subtitle: 'End this session on the device',
          destructive: true,
          onTap: () => confirmLogout(context, ref),
        ),
        SettingsTile(
          icon: Icons.delete_forever_rounded,
          title: 'Reset business data',
          subtitle: 'Delete everything and return to setup',
          destructive: true,
          onTap: onReset,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/core/security/credential_store.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/admin/widgets/settings/data_section.dart';
import 'package:brewline/features/admin/widgets/settings/printer_settings_section.dart';
import 'package:brewline/features/admin/widgets/settings/update_section.dart';
import 'package:brewline/features/onboarding/pages/onboarding_page.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/features/waiter/widgets/settings/change_password_dialog.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_footer.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/widgets/settings/settings_section_card.dart';
import 'package:brewline/shared/widgets/settings/settings_tile.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/shared/widgets/settings/language_dropdown.dart';
import 'package:brewline/shared/widgets/settings/theme_segmented_control.dart';
import 'package:brewline/shared/widgets/logout_button.dart';

/// Admin "Settings" tab.
///
/// Redesigned around the same `SettingsSectionCard` vocabulary as the waiter
/// page: a **General** card (language + theme), a **Printer** card (receipt
/// transport), an **Update** card (OTA), a **Data** card (off-device backup &
/// restore), and an **Account** card that shows the admin username and offers
/// change PIN, logout and the destructive reset — wiping the business database
/// and returning to onboarding.
class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: Breakpoints.of(context) == ScreenSize.compact
            ? Space.lg
            : Space.full,
        vertical: Space.lg,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // const _ProfileHeader(),
                // SizedBox(height: Space.x2l),
                // Section cards: a 2-column grid on desktop (≥ 905dp) so the
                // settings use the wide screen without stretching a single
                // stacked column; stacked single-column on phones/tablets.
                // A `Wrap` (not GridView) lets cards of unequal height flow
                // naturally into two equal-width columns without forcing a
                // uniform row height.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop =
                        constraints.maxWidth >= Breakpoints.expanded;
                    final gap = isDesktop ? Space.lg : 0.0;

                    if (isDesktop) {
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          // General spans the whole first row on desktop so
                          // the language + theme controls breathe.
                          SizedBox(
                            width: constraints.maxWidth,
                            child: const _GeneralCard(),
                          ),
                          // Every remaining card is half the width, minus the
                          // run gap, so they pair up two-per-row.
                          SizedBox(
                            width: _halfWidth(constraints.maxWidth, gap),
                            child: const PrinterSettingsSection(),
                          ),
                          SizedBox(
                            width: _halfWidth(constraints.maxWidth, gap),
                            child: const UpdateSection(),
                          ),
                          SizedBox(
                            width: _halfWidth(constraints.maxWidth, gap),
                            child: const DataSection(),
                          ),
                          SizedBox(
                            width: _halfWidth(constraints.maxWidth, gap),
                            child: _AccountCard(
                              onReset: () => _confirmReset(context, ref),
                            ),
                          ),
                        ],
                      );
                    }

                    // Mobile / tablet: stacked single column.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _GeneralCard(),
                        SizedBox(height: Space.lg),
                        const PrinterSettingsSection(),
                        SizedBox(height: Space.lg),
                        _AccountCard(
                          onReset: () => _confirmReset(context, ref),
                        ),
                        SizedBox(height: Space.lg),
                        const DataSection(),
                        SizedBox(height: Space.lg),
                        const UpdateSection(),
                      ],
                    );
                  },
                ),
                SizedBox(height: Space.lg),
                const SettingsFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Child width for a 2-up desktop grid: half the available width minus the
  /// run gap so two cards plus the spacing exactly fill the row.
  static double _halfWidth(double maxWidth, double gap) => (maxWidth - gap) / 2;

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _ResetConfirmDialog(),
    );

    if (confirmed != true || !context.mounted) return;
    final prefs = ref.read(sharedPreferencesProvider);
    // Clear the onboarding flag AND the stored credentials the login screen
    // validates against, so a fresh setup starts from a clean slate. The
    // credential triple goes through the backend-appropriate store (keychain
    // on mobile, prefs on desktop).
    await prefs.remove(kOnboardingCompleteKey);
    await ref.read(credentialStoreProvider).clear();
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

/// Destructive reset dialog that requires the admin to type `RESET` before the
/// reset button activates — a deliberate second factor that makes an
/// accidental or UI-glitch-triggered wipe far less likely.
class _ResetConfirmDialog extends StatefulWidget {
  const _ResetConfirmDialog();

  @override
  State<_ResetConfirmDialog> createState() => _ResetConfirmDialogState();
}

class _ResetConfirmDialogState extends State<_ResetConfirmDialog> {
  final _controller = TextEditingController();

  static const _confirmation = 'RESET';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _controller.text == _confirmation;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: UiText(
        l10n.settingsResetConfirmTitle,
        type: UiTextType.titleMedium,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UiText(l10n.settingsResetConfirmBody, type: UiTextType.bodyMedium),
          SizedBox(height: Space.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.settingsResetFieldLabel,
              helperText: l10n.settingsResetFieldHelper,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        UiButton(
          l10n.settingsResetButton,
          variant: UiButtonVariant.destructive,
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
        ),
      ],
    );
  }
}

/// General card: language + theme controls.
class _GeneralCard extends ConsumerWidget {
  const _GeneralCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageControllerProvider);
    final themePref = ref.watch(themeControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return SettingsSectionCard(
      titleHeader: l10n.settingsPreferences,
      icon: Icons.tune_rounded,
      title: l10n.settingsGeneralTitle,
      subtitle: l10n.settingsGeneralSubtitle,
      children: [
        SettingsTile(
          icon: Icons.language_rounded,
          title: l10n.settingsLanguageTitle,
          subtitle: l10n.settingsLanguageSubtitle,
          trailing: LanguageDropdown(
            value: language,
            onChanged: (value) => ref
                .read(languageControllerProvider.notifier)
                .setLanguage(value),
          ),
        ),
        ThemeSegmentedControl(
          themePref: themePref,
          onChanged: (value) =>
              ref.read(themeControllerProvider.notifier).setTheme(value),
        ),
      ],
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
    final l10n = AppLocalizations.of(context)!;

    return SettingsSectionCard(
      titleHeader: l10n.settingsSecurity,
      icon: Icons.person_rounded,
      title: l10n.settingsAccountTitle,
      subtitle: l10n.settingsAccountSubtitle,
      accent: SettingsAccent.tertiary,
      children: [
        SettingsTile(
          icon: Icons.badge_outlined,
          title: l10n.settingsSignedInAs,
          subtitle: username,
          trailing: UiText(
            l10n.roleAdmin,
            type: UiTextType.labelMedium,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        SettingsTile(
          icon: Icons.lock_reset_rounded,
          title: l10n.settingsChangePasswordTitle,
          subtitle: l10n.settingsChangePasswordSubtitle,
          onTap: () => showChangePasswordDialog(context),
        ),
        SettingsTile(
          icon: Icons.logout_rounded,
          title: l10n.logoutAction,
          subtitle: l10n.settingsLogoutSubtitle,
          destructive: true,
          onTap: () => confirmLogout(context, ref),
        ),
        SettingsTile(
          icon: Icons.delete_forever_rounded,
          title: l10n.settingsResetTitle,
          subtitle: l10n.settingsResetSubtitle,
          destructive: true,
          onTap: onReset,
        ),
      ],
    );
  }
}

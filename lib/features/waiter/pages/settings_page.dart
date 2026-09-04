import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/features/admin/settings/widgets/update_section.dart';
import 'package:brewline/features/auth/login_page.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/auth/providers/current_user_provider.dart';
import 'package:brewline/features/waiter/providers/printing_preferences_provider.dart';
import 'package:brewline/features/waiter/widgets/settings/cashout_button.dart';
import 'package:brewline/features/waiter/widgets/settings/change_password_dialog.dart';
import 'package:brewline/features/waiter/widgets/settings/print_report_button.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_footer.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_section_card.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_tile.dart';
import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/shared/widgets/settings/language_dropdown.dart';
import 'package:brewline/shared/widgets/settings/theme_segmented_control.dart';

/// All user-facing copy for the settings screen in one place so wording
/// stays consistent and easy to localize later.
class _Copy {
  static const pageTitle = 'Settings';
  static const onShift = 'On shift';

  // General
  static const generalTitle = 'General';
  static const generalSubtitle = 'Language and appearance';
  static const languageTile = 'Language';
  static const languageHint = 'Interface language for this device';

  // Account
  static const accountTitle = 'Account profile';
  static const accountSubtitle = 'Manage your session and shift reports';
  static const changePasswordTile = 'Change password';
  static const changePasswordHint = 'Update your login credentials';
  static const logoutTile = 'Log out';
  static const logoutHint = 'End this session on the device';
  static const logoutConfirmTitle = 'Log out?';
  static const logoutConfirmBody =
      'You will need to sign in again to take orders.';
  static const logoutConfirmAction = 'Log out';
  static const logoutCancelledAction = 'Stay';

  // Printing
  static const printingTitle = 'Printing';
  static const printingSubtitle = 'Receipts printed with each order';
  static const kitchenReceiptTile = 'Kitchen receipt';
  static const kitchenReceiptHint = 'Send a copy to the kitchen printer';
  static const clientReceiptTile = 'Client receipt';
  static const clientReceiptHint = 'Hand the guest their printed copy';
}

/// Static icon set for the settings screen.
class _SettingsIcons {
  static const general = Icons.tune_rounded;
  static const account = Icons.person_rounded;
  static const printing = Icons.receipt_long_rounded;

  static const language = Icons.language_rounded;
  static const password = Icons.lock_reset_rounded;
  static const logout = Icons.logout_rounded;
  static const kitchenReceipt = Icons.soup_kitchen_rounded;
  static const clientReceipt = Icons.receipt_rounded;
}

/// Settings screen, redesigned around accent-tinted
/// [SettingsSectionCard]s under a hero profile header:
///
/// * **Header** – avatar, name and live "on shift" status
/// * **General** – language dropdown + theme segmented control
/// * **Account profile** – change password, cashout & print report, logout
/// * **Printing** – kitchen / client receipt switches
/// * **Update** – OTA update card, shared with the admin settings
///
/// Phone & tablet stack the cards; wide screens place General and
/// Printing side by side with Account spanning full width. Content width
/// is capped so it stays readable. Title lives in the app bar.
///
/// When pushed as its own route (desktop waiter app bar) the page carries its
/// own [Scaffold]/[AppBar]; when embedded as an [AppShell] destination
/// ([embedded] = true) the shell already provides them, so the page renders
/// just its content to avoid a doubled header.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.embedded = false});

  final bool embedded;

  /// Content width at which General + Printing sit side by side.
  static const double _twoColumnBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: _contentPadding(context),
            vertical: Space.lg,
          ),
          children: [
            const _ProfileHeader(),
            SizedBox(height: Space.x2l),
            _ResponsiveSections(
              breakpoint: _twoColumnBreakpoint,
              general: _buildGeneralCard(ref),
              printing: _buildPrintingCard(ref),
              account: _buildAccountCard(context, ref),
              update: const UpdateSection(),
            ),
            SizedBox(height: Space.x2l),
            const SettingsFooter(),
          ],
        ),
      ),
    );

    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(
        title: const UiText(_Copy.pageTitle, type: UiTextType.titleLarge),
      ),
      body: body,
    );
  }

  double _contentPadding(BuildContext context) =>
      Breakpoints.of(context) == ScreenSize.compact ? Space.lg : Space.full;

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildGeneralCard(WidgetRef ref) {
    final language = ref.watch(languageControllerProvider);
    final themePref = ref.watch(themeControllerProvider);

    return SettingsSectionCard(
      icon: _SettingsIcons.general,
      title: _Copy.generalTitle,
      subtitle: _Copy.generalSubtitle,
      children: [
        SettingsTile(
          icon: _SettingsIcons.language,
          title: _Copy.languageTile,
          subtitle: _Copy.languageHint,
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

  Widget _buildAccountCard(BuildContext context, WidgetRef ref) {
    return SettingsSectionCard(
      icon: _SettingsIcons.account,
      title: _Copy.accountTitle,
      subtitle: _Copy.accountSubtitle,
      accent: SettingsAccent.tertiary,
      children: [
        SettingsTile(
          icon: _SettingsIcons.password,
          title: _Copy.changePasswordTile,
          subtitle: _Copy.changePasswordHint,
          onTap: () => showChangePasswordDialog(context),
        ),
        const CashoutButton(),
        const PrintReportButton(),
        SettingsTile(
          icon: _SettingsIcons.logout,
          title: _Copy.logoutTile,
          subtitle: _Copy.logoutHint,
          destructive: true,
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }

  Widget _buildPrintingCard(WidgetRef ref) {
    final preferences = ref.watch(printingPreferencesProvider);
    final controller = ref.read(printingPreferencesProvider.notifier);

    return SettingsSectionCard(
      icon: _SettingsIcons.printing,
      title: _Copy.printingTitle,
      subtitle: _Copy.printingSubtitle,
      accent: SettingsAccent.secondary,
      children: [
        SettingsTile(
          icon: _SettingsIcons.kitchenReceipt,
          title: _Copy.kitchenReceiptTile,
          subtitle: _Copy.kitchenReceiptHint,
          trailing: Switch(
            value: preferences.kitchenReceipt,
            onChanged: controller.setKitchenReceipt,
          ),
        ),
        SettingsTile(
          icon: _SettingsIcons.clientReceipt,
          title: _Copy.clientReceiptTile,
          subtitle: _Copy.clientReceiptHint,
          trailing: Switch(
            value: preferences.clientReceipt,
            onChanged: controller.setClientReceipt,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const UiText(
          _Copy.logoutConfirmTitle,
          type: UiTextType.titleMedium,
        ),
        content: const UiText(
          _Copy.logoutConfirmBody,
          type: UiTextType.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(_Copy.logoutCancelledAction),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(_Copy.logoutConfirmAction),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }
}

/// Hero card at the top of Settings: large initials avatar, user name,
/// role badge and a live "on shift" status dot. Bound to the signed-in
/// session via [currentUserProvider]; hidden until it resolves.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.x2l),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(Space.xl),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: UiText(
                    user.initials,
                    type: UiTextType.titleLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Live shift indicator pinned to the avatar corner.
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surfaceContainerLow,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    user.name,
                    type: UiTextType.headlineSmall,
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: Space.sm),
                  Wrap(
                    spacing: Space.md,
                    runSpacing: Space.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _RoleBadge(role: user.role),
                      Icon(
                        Icons.schedule_rounded,
                        size: AppSizes.iconSm + 2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: Space.xs),
                      UiText(
                        _Copy.onShift,
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
}

/// Rounded role label shown next to the shift status in the hero header.
class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: UiText(
        role,
        type: UiTextType.labelMedium,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }
}

/// Lays the section cards out: single column until [breakpoint], then
/// General and Printing share the first row while Account and Update each
/// span full width.
class _ResponsiveSections extends StatelessWidget {
  final double breakpoint;
  final Widget general;
  final Widget printing;
  final Widget account;
  final Widget update;

  const _ResponsiveSections({
    required this.breakpoint,
    required this.general,
    required this.printing,
    required this.account,
    required this.update,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final twoColumns = width >= breakpoint;
        final columnWidth = twoColumns ? (width - Space.lg) / 2 : width;

        Widget cell(Widget child) => SizedBox(width: columnWidth, child: child);

        return Wrap(
          spacing: Space.lg,
          runSpacing: Space.lg,
          children: [
            cell(general),
            cell(printing),
            SizedBox(width: width, child: account),
            SizedBox(width: width, child: update),
          ],
        );
      },
    );
  }
}

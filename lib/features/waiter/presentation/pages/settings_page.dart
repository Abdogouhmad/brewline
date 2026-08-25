import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/localization/locale_controller.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/features/waiter/presentation/widgets/settings/change_password_dialog.dart';
import 'package:brewline/features/waiter/presentation/widgets/settings/settings_footer.dart';
import 'package:brewline/features/waiter/presentation/widgets/settings/settings_section_card.dart';
import 'package:brewline/features/waiter/presentation/widgets/settings/settings_tile.dart';
import 'package:brewline/shared/providers/printing_preferences_provider.dart';
import 'package:brewline/shared/providers/user_provider.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

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
  static const themeTile = 'Theme';
  static const themeHint = 'Match your light / dark preference';

  // Account
  static const accountTitle = 'Account profile';
  static const accountSubtitle = 'Manage your session and shift reports';
  static const changePasswordTile = 'Change password';
  static const changePasswordHint = 'Update your login credentials';
  static const cashoutTile = 'Cashout & print report';
  static const cashoutHint = 'Close the shift and print a sales summary';
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

  // Feedback
  static const cashoutDone = 'Shift closed — report sent to the printer';
  static const loggedOut = 'Logged out (demo)';
}

/// Static icon set for the settings screen.
class _SettingsIcons {
  static const general = Icons.tune_rounded;
  static const account = Icons.person_rounded;
  static const printing = Icons.receipt_long_rounded;

  static const language = Icons.language_rounded;
  static const theme = Icons.brightness_6_rounded;
  static const password = Icons.lock_reset_rounded;
  static const cashout = Icons.point_of_sale_rounded;
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
///
/// Phone & tablet stack the cards; wide screens place General and
/// Printing side by side with Account spanning full width. Content width
/// is capped so it stays readable. Title lives in the app bar.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Content width at which General + Printing sit side by side.
  static const double _twoColumnBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const UiText(_Copy.pageTitle, type: UiTextType.titleLarge),
      ),
      body: Center(
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
              ),
              SizedBox(height: Space.x2l),
              const SettingsFooter(),
            ],
          ),
        ),
      ),
    );
  }

  double _contentPadding(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 ? Space.lg : Space.full;

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
          trailing: _SettingsDropdown<AppLanguage>(
            value: language,
            items: AppLanguage.values,
            label: (value) => value.label,
            onChanged: (value) => ref
                .read(languageControllerProvider.notifier)
                .setLanguage(value),
          ),
        ),
        _ThemeSegmentedControl(
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
        SettingsTile(
          icon: _SettingsIcons.cashout,
          title: _Copy.cashoutTile,
          subtitle: _Copy.cashoutHint,
          onTap: () => showUiSnackBar(
            context,
            _Copy.cashoutDone,
            type: UiSnackBarType.success,
          ),
        ),
        SettingsTile(
          icon: _SettingsIcons.logout,
          title: _Copy.logoutTile,
          subtitle: _Copy.logoutHint,
          destructive: true,
          onTap: () => _confirmLogout(context),
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

  Future<void> _confirmLogout(BuildContext context) async {
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
      // TODO: route to the login page once auth flow exists.
      if (context.mounted) {
        showUiSnackBar(context, _Copy.loggedOut, type: UiSnackBarType.info);
      }
    }
  }
}

/// Hero card at the top of Settings: large initials avatar, user name,
/// role badge and a live "on shift" status dot. Bound to
/// [currentUserProvider] (later: database-backed).
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RoleBadge(role: user.role),
                      SizedBox(width: Space.md),
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
/// General and Printing share the first row while Account spans full width.
class _ResponsiveSections extends StatelessWidget {
  final double breakpoint;
  final Widget general;
  final Widget printing;
  final Widget account;

  const _ResponsiveSections({
    required this.breakpoint,
    required this.general,
    required this.printing,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final twoColumns = width >= breakpoint;
        final columnWidth = twoColumns ? (width - Space.lg) / 2 : width;

        Widget cell(Widget child) =>
            SizedBox(width: columnWidth, child: child);

        return Wrap(
          spacing: Space.lg,
          runSpacing: Space.lg,
          children: [
            cell(general),
            cell(printing),
            SizedBox(width: width, child: account),
          ],
        );
      },
    );
  }
}

/// Theme preference as a full-width [SegmentedButton] row — three mutually
/// exclusive options read better as segments than inside a dropdown.
class _ThemeSegmentedControl extends StatelessWidget {
  final ThemePref themePref;
  final ValueChanged<ThemePref> onChanged;

  const _ThemeSegmentedControl({
    required this.themePref,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: AppSizes.iconMd / 2 + 2,
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            child: Icon(
              _SettingsIcons.theme,
              size: AppSizes.iconSm + 4,
            ),
          ),
          SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(
                  _Copy.themeTile,
                  type: UiTextType.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
                UiText(
                  _Copy.themeHint,
                  type: UiTextType.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: Space.md),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemePref>(
                    selected: {themePref},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        onChanged(selection.first),
                    segments: [
                      for (final pref in ThemePref.values)
                        ButtonSegment(
                          value: pref,
                          icon: Icon(_themeIcon(pref),
                              size: AppSizes.iconSm + 2),
                          label: Text(switch (pref) {
                            ThemePref.system => 'System',
                            ThemePref.light => 'Light',
                            ThemePref.dark => 'Dark',
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(ThemePref pref) => switch (pref) {
        ThemePref.system => Icons.brightness_auto_rounded,
        ThemePref.light => Icons.light_mode_outlined,
        ThemePref.dark => Icons.dark_mode_outlined,
      };
}

/// Compact dropdown rendered as a tile trailing control.
class _SettingsDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T value) label;
  final ValueChanged<T> onChanged;

  const _SettingsDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        borderRadius: BorderRadius.circular(Rounded.lg),
        padding: EdgeInsets.symmetric(horizontal: Space.sm),
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: UiText(
                label(item),
                type: UiTextType.labelLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
        icon: Icon(Icons.expand_more_rounded, color: colorScheme.primary),
      ),
    );
  }
}


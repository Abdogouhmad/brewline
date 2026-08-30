import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// A single settings row inside a [SettingsSectionCard].
///
/// Compose any trailing control (chevron, `Switch`, dropdown) via
/// [trailing]; set [destructive] to tint the row for dangerous actions
/// such as logout.
///
/// ```dart
/// SettingsTile(
///   icon: Icons.logout_rounded,
///   title: 'Log out',
///   destructive: true,
///   onTap: () {},
/// )
/// ```
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Tints icon + title with the error color and shows a chevron.
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contentColor = destructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return MergeSemantics(
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rounded.lg),
        ),
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: Space.sm,
        minLeadingWidth: 0,
        horizontalTitleGap: Space.lg,
        leading: CircleAvatar(
          radius: AppSizes.iconMd / 2 + 2,
          backgroundColor: destructive
              ? colorScheme.errorContainer
              : colorScheme.secondaryContainer,
          foregroundColor: destructive
              ? colorScheme.onErrorContainer
              : colorScheme.onSecondaryContainer,
          child: Icon(icon, size: AppSizes.iconSm + 4),
        ),
        title: UiText(
          title,
          type: UiTextType.titleSmall,
          fontWeight: FontWeight.w600,
          color: contentColor,
        ),
        subtitle: subtitle == null || subtitle!.isEmpty
            ? null
            : UiText(
                subtitle!,
                type: UiTextType.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
        // Switch/dropdown manage their own tap targets; only rows without
        // one become fully tappable.
        trailing: trailing ?? _defaultChevron(colorScheme),
      ),
    );
  }

  Widget? _defaultChevron(ColorScheme colorScheme) => onTap == null
      ? null
      : Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant);
}

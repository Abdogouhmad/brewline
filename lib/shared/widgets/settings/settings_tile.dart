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
    final iconBg = destructive
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final iconFg = destructive
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Rounded.lg),
          splashColor: colorScheme.onSurface.withValues(alpha: 0.06),
          highlightColor: colorScheme.onSurface.withValues(alpha: 0.04),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Space.sm),
            child: Row(
              children: [
                // Icon badge.
                Container(
                  width: AppSizes.iconLg * 1.5,
                  height: AppSizes.iconLg * 1.5,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(Rounded.xl),
                  ),
                  child: Icon(icon, size: AppSizes.iconMd, color: iconFg),
                ),
                SizedBox(width: Space.lg),
                // Title + subtitle.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UiText(
                        title,
                        type: UiTextType.titleSmall,
                        fontWeight: FontWeight.w600,
                        color: contentColor,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        SizedBox(height: Space.xs / 2),
                        UiText(
                          subtitle!,
                          type: UiTextType.bodySmall,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing widget or default chevron.
                if (trailing != null) ...[
                  SizedBox(width: Space.sm),
                  trailing!,
                ] else if (onTap != null) ...[
                  SizedBox(width: Space.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: AppSizes.iconSm + 4,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

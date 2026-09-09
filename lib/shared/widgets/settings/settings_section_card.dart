import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Accent palette applied to a section's icon badge and card top-border so
/// each card is visually distinct while staying inside the active
/// [ColorScheme].
enum SettingsAccent {
  primary,
  secondary,
  tertiary;

  ({Color background, Color foreground, Color borderColor}) resolve(
    ColorScheme scheme,
  ) => switch (this) {
    primary => (
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      borderColor: scheme.primary,
    ),
    secondary => (
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      borderColor: scheme.secondary,
    ),
    tertiary => (
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
      borderColor: scheme.tertiary,
    ),
  };
}

/// Big settings section card: tinted icon badge + title header followed by
/// row widgets ([SettingsTile]s) separated by hairline dividers.
///
/// A thin accent-colored top-border makes each section visually distinct.
/// An optional [titleHeader] renders as an uppercase eyebrow label above
/// the section title to group related cards.
///
/// Paddings scale by device type so the card feels airy on tablet/desktop
/// and compact on phones.
///
/// ```dart
/// SettingsSectionCard(
///   titleHeader: 'Preferences',
///   icon: Icons.print_rounded,
///   title: 'Printing',
///   subtitle: 'Choose which receipts print automatically',
///   accent: SettingsAccent.secondary,
///   children: [ ... ],
/// )
/// ```
class SettingsSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? titleHeader;
  final String? subtitle;
  final List<Widget> children;

  /// Icon-badge palette; defaults to [SettingsAccent.primary].
  final SettingsAccent accent;

  const SettingsSectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.titleHeader,
    this.subtitle,
    this.accent = SettingsAccent.primary,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (:background, :foreground, :borderColor) = accent.resolve(
      colorScheme,
    );
    final padding = responsiveValue(
      context,
      mobile: Space.lg,
      tablet: Space.xl,
      desktop: Space.xl,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Rounded.xl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Rounded.xl)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent top-border stripe.
            Container(height: 3, decoration: BoxDecoration(color: borderColor)),
            // Title header eyebrow (optional).
            if (titleHeader != null)
              _TitleHeader(title: titleHeader!, accentColor: borderColor),
            Padding(
              padding: EdgeInsets.fromLTRB(padding, Space.lg, padding, padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SectionHeader(
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    background: background,
                    foreground: foreground,
                  ),
                  SizedBox(
                    height: responsiveValue(
                      context,
                      mobile: Space.md,
                      desktop: Space.xl,
                    ),
                  ),
                  // Rows with dividers between them.
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 1),
                        child: Divider(
                          height: 2,
                          indent: AppSizes.iconLg * 1.5 + Space.lg,
                          thickness: 0.5,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eyebrow-style label shown above the section header when [title] is set.
/// Uses a thin tinted background strip for visual grouping.
class _TitleHeader extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _TitleHeader({required this.title, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.sm),
      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.06)),
      child: UiText(
        title.toUpperCase(),
        type: UiTextType.labelSmall,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: accentColor,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color background;
  final Color foreground;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: AppSizes.iconLg * 1.5,
          height: AppSizes.iconLg * 1.5,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(Rounded.xl),
          ),
          child: Icon(icon, size: AppSizes.iconMd, color: foreground),
        ),
        SizedBox(width: Space.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiText(
                title,
                type: UiTextType.titleMedium,
                fontWeight: FontWeight.w700,
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
      ],
    );
  }
}

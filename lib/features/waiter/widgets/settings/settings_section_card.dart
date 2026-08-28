import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Accent palette applied to a section's icon badge so each card is
/// visually distinct while staying inside the active [ColorScheme].
enum SettingsAccent {
  primary,
  secondary,
  tertiary;

  ({Color background, Color foreground}) resolve(ColorScheme scheme) =>
      switch (this) {
        primary => (
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        ),
        secondary => (
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        ),
        tertiary => (
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        ),
      };
}

/// Big settings section card: tinted icon badge + title header followed by
/// row widgets ([SettingsTile]s) separated by hairline dividers.
///
/// Paddings scale by device type so the card feels airy on tablet/desktop
/// and compact on phones.
///
/// ```dart
/// SettingsSectionCard(
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
  final String? subtitle;
  final List<Widget> children;

  /// Icon-badge palette; defaults to [SettingsAccent.primary].
  final SettingsAccent accent;

  const SettingsSectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = SettingsAccent.primary,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final padding = responsiveValue(
      context,
      mobile: Space.lg,
      tablet: Space.xl,
      desktop: Space.xl,
    );

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
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SectionHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
              accent: accent,
            ),
            SizedBox(height: responsiveValue(
              context,
              mobile: Space.sm,
              desktop: Space.md,
            )),
            // Rows with hairline dividers between them.
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: padding,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final SettingsAccent accent;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (:background, :foreground) = accent.resolve(colorScheme);

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
              UiText(title, type: UiTextType.titleMedium, fontWeight: FontWeight.w700),
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

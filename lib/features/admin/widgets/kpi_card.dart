import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/core/responsive/responsive_text.dart';
import 'package:brewline/features/admin/providers/dashboard_period.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// One headline stat on the admin dashboard.
///
/// Pairs a colour-tinted icon with a big value and a delta chip comparing
/// against the previous equal-length window ([deltaPercent]).
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Pre-formatted value (e.g. `DH 1 240.00` or `42`).
  final String value;

  /// Fractional change vs. the previous window.
  final double delta;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = Breakpoints.of(context);

    // Cards slim 15–20% on phones/tablets (smaller padding + tighter icon
    // row) so four headline stats fit without wrapping; desktop keeps the
    // original generous padding.
    final padding = switch (size) {
      ScreenSize.expanded => EdgeInsets.all(Space.lg),
      ScreenSize.medium => EdgeInsets.all(Space.lg - 2),
      ScreenSize.compact => EdgeInsets.all(Space.md),
    };

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.x2l),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    size == ScreenSize.compact ? Space.xs : Space.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(Rounded.lg),
                  ),
                  child: Icon(
                    icon,
                    size: size == ScreenSize.compact
                        ? AppSizes.iconSm + 2
                        : AppSizes.iconMd,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                Spacer(),
                _DeltaChip(delta: delta, compact: size != ScreenSize.expanded),
              ],
            ),
            SizedBox(height: size == ScreenSize.expanded ? Space.md : Space.sm),
            UiText(
              label,
              type: UiTextType.labelLarge,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: context.responsiveFontSize(14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Space.xs),
            UiText(
              value,
              type: UiTextType.headlineSmall,
              fontWeight: FontWeight.w800,
              fontSize: size == ScreenSize.expanded
                  ? context.responsiveFontSize(26)
                  : context.responsiveFontSize(22),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static double responsiveVSpace(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 ? Space.lg : Space.md;
  }
}

/// Compact up/down pill showing the fractional change vs the previous window.
class _DeltaChip extends StatelessWidget {
  final double delta;

  /// Drops the icon on phones so the chip fits the denser KPI row.
  final bool compact;

  const _DeltaChip({required this.delta, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final direction = delta.abs() < 0.001
        ? _Direction.flat
        : (delta > 0 ? _Direction.up : _Direction.down);

    final (Color foreground, Color background) = switch (direction) {
      _Direction.up => (
        colorScheme.onTertiaryContainer,
        colorScheme.tertiaryContainer,
      ),
      _Direction.down => (
        colorScheme.onErrorContainer,
        colorScheme.errorContainer,
      ),
      _Direction.flat => (
        colorScheme.onSurfaceVariant,
        colorScheme.surfaceContainerHighest,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Space.sm : Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(
              switch (direction) {
                _Direction.up => Icons.trending_up_rounded,
                _Direction.down => Icons.trending_down_rounded,
                _Direction.flat => Icons.remove_rounded,
              },
              size: AppSizes.iconSm,
              color: foreground,
            ),
            SizedBox(width: 2),
          ],
          UiText(
            '${direction == _Direction.up ? '+' : ''}'
            '${(delta * 100).round()}%',
            type: UiTextType.labelSmall,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ],
      ),
    );
  }
}

enum _Direction { up, down, flat }

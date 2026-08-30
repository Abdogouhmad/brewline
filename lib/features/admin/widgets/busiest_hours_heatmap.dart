import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive_text.dart';
import 'package:brewline/features/admin/providers/analytics_provider.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'dashboard_card.dart';

/// "When are we busiest?" as a **day × time-bucket heatmap** instead of the
/// old dense 24-hour bar series.
///
/// Rows are 2-hour buckets from 7am–11pm, columns Monday–Sunday. Cell colour
/// goes from a faint primary tint (quiet) to full [ColorScheme.primary]
/// (busiest), scaled to the peak cell in the current period. Exact counts are
/// shown on tap (SnackBar) / hover (Tooltip), never crammed into every cell —
/// that crowding was the bug this redesign fixes.
class BusiestHoursHeatmap extends ConsumerWidget {
  const BusiestHoursHeatmap({super.key});

  static const List<String> _dayLabels = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

  /// Number of cells in each heatmap row (7 days × the fixed 8 buckets).
  static const int _buckets = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = ref.watch(busiestHoursHeatmapProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DashboardCard(
      title: 'Busiest hours',
      icon: Icons.schedule_rounded,
      trailing: cells.when(
        data: (items) => UiText(
          '${items.fold<int>(0, (s, c) => s + c.orders)} orders',
          type: UiTextType.labelLarge,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
      child: cells.when(
        loading: () => const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: EdgeInsets.symmetric(vertical: Space.xl),
          child: Center(
            child: UiText(
              'Couldn\'t load the hour data.',
              type: UiTextType.bodyMedium,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        data: (items) => _HeatmapGrid(
          cells: items,
          dayLabels: _dayLabels,
          buckets: _buckets,
        ),
      ),
    );
  }
}

/// Renders the 8 × 7 grid with day headers, sizing cells as a fraction of the
/// available width (LayoutBuilder) so it reflows on every ScreenSize instead
/// of using a fixed pixel cell size.
class _HeatmapGrid extends StatelessWidget {
  final List<HeatmapCell> cells;
  final List<String> dayLabels;
  final int buckets;

  const _HeatmapGrid({
    required this.cells,
    required this.dayLabels,
    required this.buckets,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final peak = cells.fold<int>(0, (m, c) => c.orders > m ? c.orders : m);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - _kLabelWidth - Space.xs) / dayLabels.length;
        final cellHeight = (cellWidth * 0.62).clamp(22.0, 34.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Day headers (Mo–Su) aligned over the data columns.
            Padding(
              padding: EdgeInsets.only(
                left: _kLabelWidth + Space.xs,
                bottom: Space.sm,
              ),
              child: Row(
                children: [
                  for (final label in dayLabels)
                    Expanded(
                      child: UiText(
                        label,
                        type: UiTextType.labelSmall,
                        color: colorScheme.onSurfaceVariant,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            for (var b = 0; b < buckets; b++)
              _buildRow(context, b, cellHeight, peak, colorScheme),
          ],
        );
      },
    );
  }

  /// One bucket row: hour label on the left, then one coloured cell per day.
  Widget _buildRow(
    BuildContext context,
    int bucket,
    double cellHeight,
    int peak,
    ColorScheme colorScheme,
  ) {
    final row = cells.where((c) => c.bucketHour == 7 + bucket * 2).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: Space.xs),
      child: Row(
        children: [
          SizedBox(
            width: _kLabelWidth,
            child: UiText(
              _bucketLabel(row.first.bucketHour),
              type: UiTextType.labelSmall,
              fontSize: context.responsiveFontSize(11),
              color: colorScheme.onSurfaceVariant,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: Space.xs),
          for (final cell in row)
            Expanded(
              child: _HeatCell(cell: cell, height: cellHeight, peak: peak),
            ),
        ],
      ),
    );
  }

  /// Column of the grid dedicated to the time labels.
  static const double _kLabelWidth = 40;

  /// Formats a bucket start hour (`7, 9, …, 21`) into `7–9`, `9–11`, `11–13`,
  /// … using the 12-hour clock so it reads naturally.
  static String _bucketLabel(int start) {
    String h(int v) {
      final m = v % 12;
      return m == 0 ? '12' : '$m';
    }

    // Collapse the width at noon by comparing hours directly: the bucket
    // spans [start, start + 2).
    return '${h(start)}–${h(start + 2)}';
  }
}

/// A single heatmap cell: tint scaled to [peak], with tap/hover labels.
class _HeatCell extends StatelessWidget {
  final HeatmapCell cell;
  final double height;
  final int peak;

  const _HeatCell({
    required this.cell,
    required this.height,
    required this.peak,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = peak <= 0 ? 0.0 : (cell.orders / peak).clamp(0.0, 1.0);
    // Quiet slots keep a ~8% tint so the empty grid still reads; the busiest
    // cell reaches the full primary colour.
    final opacity = 0.08 + 0.92 * ratio;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: _label,
        child: InkWell(
          borderRadius: BorderRadius.circular(Rounded.sm),
          onTap: () => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(_label),
                duration: const Duration(seconds: 1),
              ),
            ),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(Rounded.sm),
            ),
          ),
        ),
      ),
    );
  }

  String get _label {
    final day = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][cell.weekday];
    return '$day · ${_formatBucket(cell.bucketHour)} '
        '· ${cell.orders} order${cell.orders == 1 ? '' : 's'}';
  }

  static String _formatBucket(int start) {
    String h(int v) {
      final m = v % 12 == 0 ? 12 : v % 12;
      return '$m';
    }

    return '${h(start)}–${h(start + 2)}';
  }
}

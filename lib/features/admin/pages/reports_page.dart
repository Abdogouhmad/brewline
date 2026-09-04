import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/features/admin/providers/sales_trend_provider.dart';
import 'package:brewline/features/admin/widgets/busiest_hours_heatmap.dart';
import 'package:brewline/features/admin/widgets/category_mix_bars.dart';
import 'package:brewline/features/admin/widgets/dashboard_card.dart';
import 'package:brewline/features/admin/widgets/period_selector.dart';
import 'package:brewline/features/admin/widgets/revenue_line_chart.dart';
import 'package:brewline/features/admin/widgets/team_performance.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Admin "Reports" tab: revenue over time, category mix, busiest hours and
/// team performance — all for the period picked with [PeriodSelector].
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  static const double _twoColumnBreakpoint = 1100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = Breakpoints.of(context) == ScreenSize.compact;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          'Performance',
          type: UiTextType.headlineSmall,
          fontWeight: FontWeight.w800,
        ),
        SizedBox(height: Space.xs),
        UiText(
          'Revenue, what sells and when.',
          type: UiTextType.bodyMedium,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Space.lg : Space.full,
        vertical: Space.lg,
      ),
      children: [
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              SizedBox(height: Space.md),
              SizedBox(width: double.infinity, child: const PeriodSelector()),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const PeriodSelector(),
            ],
          ),
        SizedBox(height: Space.lg),
        const _RevenueTrendCard(),
        SizedBox(height: Space.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= _twoColumnBreakpoint;
            final columnWidth = twoColumns
                ? (constraints.maxWidth - Space.lg) / 2
                : constraints.maxWidth;

            Widget cell(Widget child) =>
                SizedBox(width: columnWidth, child: child);

            return Wrap(
              spacing: Space.lg,
              runSpacing: Space.lg,
              children: [
                cell(const CategoryMixBars()),
                cell(const BusiestHoursHeatmap()),
              ],
            );
          },
        ),
        SizedBox(height: Space.lg),
        const TeamPerformance(),
      ],
    );
  }
}

/// The headline revenue line chart with the period total as a trailing label.
class _RevenueTrendCard extends ConsumerWidget {
  const _RevenueTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(revenueTrendProvider);

    return DashboardCard(
      title: 'Revenue over time',
      icon: Icons.show_chart_rounded,
      trailing: trend.when(
        data: (points) => UiText(
          formatPrice(points.fold<double>(0, (s, p) => s + p.revenue)),
          type: UiTextType.titleMedium,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
        ),
        loading: () => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
      child: trend.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: EdgeInsets.symmetric(vertical: Space.xl),
          child: Center(
            child: UiText(
              'Couldn\'t load the revenue trend.',
              type: UiTextType.bodyMedium,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        data: (points) => RevenueLineChart(points: points),
      ),
    );
  }
}

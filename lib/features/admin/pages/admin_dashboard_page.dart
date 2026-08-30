import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/features/admin/providers/dashboard_provider.dart';
import 'package:brewline/features/admin/providers/sales_trend_provider.dart';
import 'package:brewline/features/admin/widgets/dashboard_card.dart';
import 'package:brewline/features/admin/widgets/dashboard_header.dart';
import 'package:brewline/features/admin/widgets/kpi_card.dart';
import 'package:brewline/features/admin/widgets/low_stock_alerts.dart';
import 'package:brewline/features/admin/widgets/quick_actions_row.dart';
import 'package:brewline/features/admin/widgets/revenue_trend_chart.dart';
import 'package:brewline/features/admin/widgets/shift_status_card.dart';
import 'package:brewline/features/admin/widgets/top_products_list.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Admin landing tab: live KPIs, revenue trend, top sellers and stock alerts
/// for the selected period — the at-a-glance answer to "how is the café doing?"
///
/// Layout (spec `improve.md`):
/// 1. header + period selector
/// 2. four KPI cards
/// 3. wide revenue overview with a right rail stacking shift status + quick
///    actions on wide screens (stacked on phones/tablets)
/// 4. top sellers and low-stock alerts side by side when space allows
class AdminDashboardPage extends ConsumerWidget {
  /// Fired when a quick action wants to move to another tab
  /// (Staff = 1, Reports = 2, Menu = 3).
  final ValueChanged<int> onNavigate;

  const AdminDashboardPage({super.key, required this.onNavigate});

  static const double _twoColumnBreakpoint = 1100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: _contentPadding(context),
        vertical: Space.lg,
      ),
      children: [
        const DashboardHeader(),
        SizedBox(height: Space.lg),
        const _KpiGrid(),
        SizedBox(height: Space.lg),
        _RevenueAndRail(onNavigate: onNavigate),
        SizedBox(height: Space.lg),
        const _SecondaryRow(),
      ],
    );
  }

  double _contentPadding(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 ? Space.lg : Space.full;
}

/// Revenue overview (wide) beside the shift status + quick actions rail.
class _RevenueAndRail extends StatelessWidget {
  /// Jump target for the quick actions (see [QuickActionsRow.onNavigate]).
  final ValueChanged<int> onNavigate;

  const _RevenueAndRail({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AdminDashboardPage._twoColumnBreakpoint;
        const revenue = _RevenueSection();
        const shift = ShiftStatusCard();

        // Rail never dips below 320dp so quick action labels stay readable.
        final railWidth = wide
            ? (constraints.maxWidth / 3).clamp(320.0, 480.0)
            : constraints.maxWidth;
        final revenueWidth = wide
            ? constraints.maxWidth - railWidth - Space.lg
            : constraints.maxWidth;

        Widget rail() => SizedBox(
          width: railWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              shift,
              SizedBox(height: Space.lg),
              QuickActionsRow(onNavigate: onNavigate),
            ],
          ),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: revenueWidth, child: revenue),
            SizedBox(width: wide ? Space.lg : 0),
            rail(),
          ],
        );
      },
    );
  }
}

/// Top sellers and low-stock alerts side by side on wide screens.
class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= AdminDashboardPage._twoColumnBreakpoint;
        final columnWidth = wide
            ? (constraints.maxWidth - Space.lg) / 2
            : constraints.maxWidth;

        Widget cell(Widget child) => SizedBox(width: columnWidth, child: child);

        return Wrap(
          spacing: Space.lg,
          runSpacing: Space.lg,
          children: [
            cell(const TopProductsList()),
            cell(const LowStockAlerts()),
          ],
        );
      },
    );
  }
}

/// The four headline stat cards, fed by [dashboardKpisProvider].
class _KpiGrid extends ConsumerWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(dashboardKpisProvider);

    final (revenue, orders, items, avg) = switch (kpis) {
      AsyncData(:final value) => (
        formatPrice(value.revenue),
        '${value.orderCount}',
        '${value.itemCount}',
        formatPrice(value.avgOrderValue),
      ),
      _ => ('—', '—', '—', '—'),
    };
    final deltaKpis = switch (kpis) {
      AsyncData(:final value) => value,
      _ => PeriodKpis.empty,
    };

    // Summary cards: 2 across on phones, 3 on tablets, 4 on desktop, with a
    // fixed row height so the denser compact card never overflows.
    final size = Breakpoints.of(context);
    final (columns, rowHeight) = switch (size) {
      ScreenSize.compact => (2, 132.0),
      ScreenSize.medium => (3, 140.0),
      ScreenSize.expanded => (4, 152.0),
    };

    return ResponsiveGrid(
      padding: EdgeInsets.zero,
      mainAxisExtent: rowHeight,
      mobileColumns: columns,
      tabletColumns: columns,
      desktopColumns: columns,
      children: [
        KpiCard(
          icon: Icons.attach_money_rounded,
          label: 'Revenue',
          value: revenue,
          delta: deltaKpis.revenueDelta,
        ),
        KpiCard(
          icon: Icons.receipt_long_rounded,
          label: 'Orders',
          value: orders,
          delta: deltaKpis.orderDelta,
        ),
        KpiCard(
          icon: Icons.local_mall_outlined,
          label: 'Items sold',
          value: items,
          delta: 0,
        ),
        KpiCard(
          icon: Icons.shopping_basket_outlined,
          label: 'Avg. order',
          value: avg,
          delta: deltaKpis.avgDelta,
        ),
      ],
    );
  }
}

/// Bar chart of revenue over the period, with the period total up top.
class _RevenueSection extends ConsumerWidget {
  const _RevenueSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(revenueTrendProvider);

    return DashboardCard(
      title: 'Revenue overview',
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
          height: 180,
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
        data: (points) => RevenueTrendChart(points: points),
      ),
    );
  }
}

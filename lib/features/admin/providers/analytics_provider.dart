import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/core/repositories/sales_query_repository.dart';
import 'package:brewline/features/admin/providers/dashboard_period.dart';

/// Revenue mix by product category for the selected period — drives the
/// Reports "Category mix" bars. Recomputed on period or journal changes.
final categoryMixProvider = FutureProvider<List<CategoryRevenue>>((ref) async {
  final range = periodRange(ref.watch(dashboardPeriodProvider), DateTime.now());
  final journal = await ref.watch(orderJournalRepositoryProvider.future);
  ref.watch(journalMutationProvider);
  return journal.revenueByCategory(range.from, range.to);
});

/// One slot of the 24-hour busiest-hours series.
class HourPoint {
  final int hour;
  final int orders;

  const HourPoint({required this.hour, required this.orders});
}

/// Fixed 0→23 hour slots of order counts (not revenue) — "when are we busiest?"
/// for staffing decisions. Quiet hours stay in place so the chart shape is
/// stable across days.
final busiestHoursProvider = FutureProvider<List<HourPoint>>((ref) async {
  final range = periodRange(ref.watch(dashboardPeriodProvider), DateTime.now());
  final journal = await ref.watch(orderJournalRepositoryProvider.future);
  ref.watch(journalMutationProvider);
  final buckets = await journal.revenueByHour(range.from, range.to);
  final ordersByHour = {for (final b in buckets) b.hour: b.orderCount};
  return [
    for (var hour = 0; hour < 24; hour++)
      HourPoint(hour: hour, orders: ordersByHour[hour] ?? 0),
  ];
});

/// Team performance: sales totals credited to each waiter, ranked by revenue.
final waiterPerformanceProvider = FutureProvider<List<WaiterSales>>((
  ref,
) async {
  final range = periodRange(ref.watch(dashboardPeriodProvider), DateTime.now());
  final journal = await ref.watch(orderJournalRepositoryProvider.future);
  ref.watch(journalMutationProvider);
  return journal.salesByWaiter(range.from, range.to);
});

/// One cell of the busiest-hours heatmap: [orders] in a (weekday × 2h bucket)
/// slot.
class HeatmapCell {
  /// Local weekday, Monday = 0 … Sunday = 6.
  final int weekday;

  /// Start hour of the 2-hour bucket (7, 9, …, 21).
  final int bucketHour;

  final int orders;

  const HeatmapCell({
    required this.weekday,
    required this.bucketHour,
    required this.orders,
  });
}

/// Open hours bucketed into 2-hour slots, 7am → 11pm, per weekday.
///
/// Sunday–Saturday SQL rows are remapped to a Monday-first axis and
/// zero-filled so the heatmap always renders a stable 7 (days) × 8 (buckets)
/// shape — quiet slots stay in place rather than collapsing.
final busiestHoursHeatmapProvider = FutureProvider<List<HeatmapCell>>((
  ref,
) async {
  final range = periodRange(ref.watch(dashboardPeriodProvider), DateTime.now());
  final sales = await ref.watch(salesQueryRepositoryProvider.future);
  ref.watch(journalMutationProvider);
  final counts = await sales.ordersByWeekdayHour(range.from, range.to);

  final byKey = {for (final c in counts) '${c.weekday}:${c.hour}': c.orders};
  const startHour = 7;
  const buckets = 8;
  return [
    for (var weekday = 0; weekday < 7; weekday++)
      for (var b = 0; b < buckets; b++)
        HeatmapCell(
          weekday: weekday,
          bucketHour: startHour + b * 2,
          orders: [0, 1]
              .map((h) => byKey['$weekday:${startHour + b * 2 + h}'] ?? 0)
              .fold<int>(0, (sum, n) => sum + n),
        ),
  ];
});

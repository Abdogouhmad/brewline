import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/features/admin/providers/dashboard_period.dart';

/// One bar on the revenue chart — a label plus the amount for that bucket.
class TrendPoint {
  final String label;
  final double revenue;

  const TrendPoint({required this.label, required this.revenue});
}

/// Revenue series for the selected period: hourly buckets for Today, daily
/// for 7/30 days. Missing buckets are filled with 0 so the chart keeps a
/// stable shape (no gaps for quiet days).
final revenueTrendProvider = FutureProvider<List<TrendPoint>>((ref) async {
  final now = DateTime.now();
  final period = ref.watch(dashboardPeriodProvider);
  final range = periodRange(period, now);

  final journal = await ref.watch(orderJournalRepositoryProvider.future);
  ref.watch(journalMutationProvider);

  if (period == DashboardPeriod.today) {
    final buckets = await journal.revenueByHour(range.from, range.to);
    final revenueByHour = {for (final b in buckets) b.hour: b.revenue};
    return [
      for (var hour = 0; hour <= now.hour; hour++)
        TrendPoint(label: '$hour', revenue: revenueByHour[hour] ?? 0),
    ];
  }

  final days = await journal.revenuePerDay(range.from, range.to);
  final revenueByDay = {for (final d in days) d.day: d.revenue};
  final totalDays = range.length.inDays;
  return [
    for (var i = 0; i < totalDays; i++)
      TrendPoint(
        label: period == DashboardPeriod.month
            ? range.from.add(Duration(days: i)).day.toString()
            : _weekdayShort(range.from.add(Duration(days: i)).weekday),
        revenue: revenueByDay[range.from.add(Duration(days: i))] ?? 0,
      ),
  ];
});

String _weekdayShort(int weekday) =>
    const ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'][weekday];

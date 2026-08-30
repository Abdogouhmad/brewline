import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/features/admin/providers/dashboard_period.dart';

/// The headline numbers on the dashboard with their delta vs an equal-length
/// previous window. Recomputes whenever the period or the journal changes.
class PeriodKpis {
  final double revenue;
  final int orderCount;
  final int itemCount;
  final double avgOrderValue;

  /// Fractional change vs. the previous window (see [deltaPercent]).
  final double revenueDelta;
  final double orderDelta;
  final double avgDelta;

  const PeriodKpis({
    required this.revenue,
    required this.orderCount,
    required this.itemCount,
    required this.avgOrderValue,
    required this.revenueDelta,
    required this.orderDelta,
    required this.avgDelta,
  });

  /// Zeroed stats with no delta — shown while the journal is still loading.
  static const empty = PeriodKpis(
    revenue: 0,
    orderCount: 0,
    itemCount: 0,
    avgOrderValue: 0,
    revenueDelta: 0,
    orderDelta: 0,
    avgDelta: 0,
  );
}

final dashboardKpisProvider = FutureProvider<PeriodKpis>((ref) async {
  final now = DateTime.now();
  final range = periodRange(ref.watch(dashboardPeriodProvider), now);
  final previous = previousRange(range);

  final journal = await ref.watch(orderJournalRepositoryProvider.future);
  ref.watch(journalMutationProvider);

  final current = await journal.statsBetween(range.from, range.to);
  final past = await journal.statsBetween(previous.from, previous.to);

  return PeriodKpis(
    revenue: current.revenue,
    orderCount: current.orderCount,
    itemCount: current.itemCount,
    avgOrderValue: current.avgOrderValue,
    revenueDelta: deltaPercent(current.revenue, past.revenue),
    orderDelta: deltaPercent(
      current.orderCount.toDouble(),
      past.orderCount.toDouble(),
    ),
    avgDelta: deltaPercent(current.avgOrderValue, past.avgOrderValue),
  );
});

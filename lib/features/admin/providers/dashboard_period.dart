import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The time window shown by the admin Dashboard and Reports tabs.
enum DashboardPeriod {
  today('Today'),
  week('Last 7 days'),
  month('Last 30 days');

  const DashboardPeriod(this.label);

  /// Human-readable label for segmented controls.
  final String label;
}

/// A half-open `[from, to)` window.
class DateRange {
  final DateTime from;
  final DateTime to;

  const DateRange({required this.from, required this.to});

  Duration get length => to.difference(from);
}

/// Half-open window for [period], measured from [now]'s local day.
DateRange periodRange(DashboardPeriod period, DateTime now) {
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  switch (period) {
    case DashboardPeriod.today:
      return DateRange(from: dayStart, to: dayEnd);
    case DashboardPeriod.week:
      return DateRange(
        from: dayStart.subtract(const Duration(days: 6)),
        to: dayEnd,
      );
    case DashboardPeriod.month:
      return DateRange(
        from: dayStart.subtract(const Duration(days: 29)),
        to: dayEnd,
      );
  }
}

/// The window of equal length immediately before [range] — the baseline for
/// the KPIs' delta chips (Today → yesterday, 7d → the week before, ...).
DateRange previousRange(DateRange range) {
  final length = range.length;
  return DateRange(
    from: range.from.subtract(length),
    to: range.to.subtract(length),
  );
}

/// Percentage change from [past] to [current], as a fraction. Returns 1.0
/// when the past baseline is zero but current isn't, else 0 — no divide-by-zero.
double deltaPercent(double current, double past) {
  if (past <= 0) return current > 0 ? 1.0 : 0;
  return (current - past) / past;
}

/// The period selected by the admin — shared by the Dashboard and Reports tabs.
class DashboardPeriodController extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() => DashboardPeriod.today;

  void set(DashboardPeriod period) => state = period;
}

final dashboardPeriodProvider =
    NotifierProvider<DashboardPeriodController, DashboardPeriod>(
      DashboardPeriodController.new,
    );

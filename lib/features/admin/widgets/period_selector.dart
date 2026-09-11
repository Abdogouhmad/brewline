import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/admin/providers/dashboard_period.dart';
import 'package:brewline/l10n/app_localizations.dart';

/// Today / Last 7 days / Last 30 days segmented control.
///
/// The single source of truth for "what window am I looking at" across the
/// Dashboard and Reports tabs — both watch [dashboardPeriodProvider].
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<DashboardPeriod>(
      selected: {period},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.labelMedium,
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Space.md),
        ),
      ),
      onSelectionChanged: (selection) =>
          ref.read(dashboardPeriodProvider.notifier).set(selection.first),
      segments: [
        for (final p in DashboardPeriod.values)
          ButtonSegment(value: p, label: Text(_periodLabel(l10n, p))),
      ],
    );
  }

  /// Localized label for a period. The enum's own `.label` stays English (it
  /// is a data-layer constant); display copy is resolved here per-locale.
  static String _periodLabel(AppLocalizations l10n, DashboardPeriod p) {
    return switch (p) {
      DashboardPeriod.today => l10n.adminDashboardPeriodToday,
      DashboardPeriod.week => l10n.adminDashboardPeriodWeek,
      DashboardPeriod.month => l10n.adminDashboardPeriodMonth,
    };
  }
}

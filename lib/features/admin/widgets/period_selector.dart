import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/admin/providers/dashboard_period.dart';

/// Today / Last 7 days / Last 30 days segmented control.
///
/// The single source of truth for "what window am I looking at" across the
/// Dashboard and Reports tabs — both watch [dashboardPeriodProvider].
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(dashboardPeriodProvider);

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
          ButtonSegment(value: p, label: Text(p.label)),
      ],
    );
  }
}

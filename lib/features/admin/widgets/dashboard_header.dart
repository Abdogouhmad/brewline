import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'period_selector.dart';

/// Top strip of the admin dashboard: greeting, today's date and the period
/// selector, so "how are we doing, and over what window" are answered at a
/// glance before the admin reads any number. On phones the selector drops to
/// its own full-width row (it can't sit beside the title at that width).
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final compact = Breakpoints.of(context) == ScreenSize.compact;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          _greeting(now.hour),
          type: UiTextType.headlineSmall,
          fontWeight: FontWeight.w800,
        ),
        SizedBox(height: Space.xs),
        UiText(
          _formatDate(now),
          type: UiTextType.bodyMedium,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          SizedBox(height: Space.md),
          SizedBox(width: double.infinity, child: const PeriodSelector()),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        const PeriodSelector(),
      ],
    );
  }

  static String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

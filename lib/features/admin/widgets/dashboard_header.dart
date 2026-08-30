import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'period_selector.dart';

/// Top strip of the admin dashboard: greeting, today's date and the period
/// selector, so "how are we doing, and over what window" are answered at a
/// glance before the admin reads any number.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Row(
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
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

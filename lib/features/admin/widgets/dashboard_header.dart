import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          _greeting(l10n, now.hour),
          type: UiTextType.headlineSmall,
          fontWeight: FontWeight.w800,
        ),
        SizedBox(height: Space.xs),
        UiText(
          _formatDate(context, now),
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

  static String _greeting(AppLocalizations l10n, int hour) {
    if (hour < 12) return l10n.adminDashboardGreetingMorning;
    if (hour < 18) return l10n.adminDashboardGreetingAfternoon;
    return l10n.adminDashboardGreetingEvening;
  }

  /// Today's date in the active locale, e.g. `10 September 2026` (en) or
  /// `10 septembre 2026` (fr) — via `intl`'s DateFormat rather than a
  /// hardcoded month list (improve.md §5).
  static String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMd(locale).format(date);
  }
}

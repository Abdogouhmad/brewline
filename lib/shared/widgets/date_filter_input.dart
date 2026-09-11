import 'package:flutter/material.dart';

import 'package:brewline/core/utils/date_format.dart';
import 'package:brewline/l10n/app_localizations.dart';

/// Read-only date-window control that opens the range picker on tap.
///
/// Shared by the Sales Log and Cashout Log pages. [showTodayButton] controls
/// whether a "Today" short-cut appears when no range is active (the Sales Log
/// defaults to today, so it benefits from one; the Cashout Log does not).
class DateFilterInput extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final VoidCallback? onToday;
  final bool showTodayButton;

  const DateFilterInput({
    super.key,
    required this.range,
    required this.onTap,
    required this.onClear,
    this.onToday,
    this.showTodayButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.dateFilterRange,
        prefixIcon: const Icon(Icons.date_range_outlined),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          range == null
              ? l10n.dateFilterAllDates
              : '${formatDateShort(range!.start)} – '
                    '${formatDateShort(range!.end)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (range == null && showTodayButton)
              TextButton(
                onPressed: onToday,
                child: Text(l10n.dateFilterToday),
              ),
            if (range != null)
              IconButton(
                tooltip: l10n.dateFilterClearTooltip,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

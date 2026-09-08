import 'package:flutter/material.dart';

import 'package:brewline/core/utils/date_format.dart';

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
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Date range',
        prefixIcon: Icon(Icons.date_range_outlined),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          range == null
              ? 'All dates'
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
                child: const Text('Today'),
              ),
            if (range != null)
              IconButton(
                tooltip: 'Show all dates',
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

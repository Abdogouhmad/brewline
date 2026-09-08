/// Shared date formatting helpers for list/table UIs.
library;

/// Abbreviated month names (`Jan`…`Dec`), `_months[month - 1]` indexed.
const List<String> kMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [d] as `5 Sep 2026 · 14:30` — the shared log-table date style.
String formatDateWithTime(DateTime d) =>
    '${d.day} ${kMonthNames[d.month - 1]} ${d.year} · '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Formats [d] as a compact `5/9/2026` (day/month/year) date range label.
String formatDateShort(DateTime d) => '${d.day}/${d.month}/${d.year}';

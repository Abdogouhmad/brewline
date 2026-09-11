/// Shared date formatting helpers for list/table UIs.
library;

import 'package:intl/intl.dart';

/// The locale the active UI is showing in (see `price_format.dart`'s notes).
String get _activeLocale => Intl.defaultLocale ?? 'en';

/// Formats [d] as `5 Sep 2026 · 14:30` — the shared log-table date style —
/// with month names localised to the active locale (`5 sept. 2026 · 14:30` in
/// French).
String formatDateWithTime(DateTime d) =>
    formatDateWithTimeIn(_activeLocale, d);

/// Locale-explicit variant used by the receipt layer (§6).
String formatDateWithTimeIn(String locale, DateTime d) =>
    _dateFormat('d MMM y \u00b7 HH:mm', locale).format(d);

/// Formats [d] as a compact `5/9/2026` (day/month/year) date range label.
///
/// The explicit `d/M/y` pattern is deliberate: this café's context (Morocco,
/// French/English symmetry) treats day-first as canonical, so both locales
/// render `5/9/2026` rather than intl's US-style `9/5/2026` — the localised
/// month-name format above is where the two languages visibly diverge.
String formatDateShort(DateTime d) =>
    DateFormat('d/M/y', _intlLocaleOrNull(_activeLocale)).format(d);

/// Returns [locale] for locales whose symbols intl loads lazily, or `null` for
/// English so the built-in en_US tables are used without `initializeDateFormatting`.
String? _intlLocaleOrNull(String locale) =>
    (locale == 'en' || locale == 'en_US') ? null : locale;

/// [DateFormat] with [locale]; English defaults to intl's baked-in symbols.
DateFormat _dateFormat(String pattern, String locale) =>
    DateFormat(pattern, _intlLocaleOrNull(locale));
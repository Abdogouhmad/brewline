/// Price display helpers shared across the whole app (menu catalog, admin
/// dashboards, order cart and receipt previews).
library;

import 'package:intl/intl.dart';

/// Currency shown across the UI until multi-currency lands.
const String kCurrencySymbol = 'DH';

/// The locale the active UI is showing in, as tracked by intl.
///
/// `main()` keeps this in sync with Settings → General language (via
/// `initializeIntlLocale`), so formatting follows the app language even in
/// code paths without a `BuildContext`. Tests leave it unset and fall back to
/// 'en', whose number symbols are built into intl — no init needed.
String get _activeLocale => Intl.defaultLocale ?? 'en';

/// Formats [cents] as a display price for the active locale, e.g.
/// `450 -> DH 4.50` (English) / `4,50 DH` (French). The canonical formatter —
/// all money lives in integer cents (see '_cents' DB columns).
///
/// Thousands separators, decimal separators and currency placement all come
/// from intl for the active locale, not from string concatenation.
String formatPriceCents(int cents) => formatPriceCentsIn(_activeLocale, cents);

/// Locale-explicit variant used by the receipt layer (§6), which prints in a
/// fixed language independent of the till's current UI language.
String formatPriceCentsIn(String locale, int cents) =>
    _withSign(locale, _moneyFormat(locale).format(cents.abs() / 100), cents < 0);

/// Formats [amount] (already in major currency units) as a display price,
/// e.g. `4.5 -> DH 4.50`. Prefer [formatPriceCents] for money values.
String formatPrice(double amount) =>
    _withSign(_activeLocale, _moneyFormat(_activeLocale).format(amount.abs()), amount < 0);

/// Reusable currency formatter for [locale], symbol placed per that locale's
/// currency pattern (English: `DH 4.50`, French: `4,50 DH`).
NumberFormat _moneyFormat(String locale) {
  // Trailing space inside the symbol means prefix-locales like English render
  // `DH 4.50` with a natural gap; suffix-locales already put a space in their
  // currency pattern and any trailing space is trimmed here.
  return NumberFormat.currency(
    locale: locale,
    symbol: '$kCurrencySymbol ',
    decimalDigits: 2,
  );
}

/// Applies the sign consistently: English keeps it between symbol and number
/// (`DH -1.50`), suffix-locales put it before the whole amount (`-4,50 DH`).
String _withSign(String locale, String formatted, bool negative) {
  final trimmed = formatted.trimRight();
  if (!negative) return trimmed;
  final prefix = '$kCurrencySymbol ';
  if (trimmed.startsWith(prefix)) {
    return '$prefix-${trimmed.substring(prefix.length)}';
  }
  return '-$trimmed';
}
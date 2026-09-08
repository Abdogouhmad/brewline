/// Price display helpers shared across the whole app (menu catalog, admin
/// dashboards, order cart and receipt previews).
library;

/// Currency shown across the UI until multi-currency lands.
const String kCurrencySymbol = r'DH ';

/// Formats [cents] as a display price, e.g. `450 -> DH 4.50`. The canonical
/// formatter — all money lives in integer cents (see '_cents' DB columns).
String formatPriceCents(int cents) =>
    '$kCurrencySymbol${(cents / 100).toStringAsFixed(2)}';

/// Formats [amount] (already in major currency units) as a display price,
/// e.g. `4.5 -> DH 4.50`. Prefer [formatPriceCents] for money values.
String formatPrice(double amount) =>
    '$kCurrencySymbol${amount.toStringAsFixed(2)}';

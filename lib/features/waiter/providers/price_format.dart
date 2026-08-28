/// Price display helpers shared across waiter-facing data (menu catalog
/// and order cart).
library;

/// Currency shown across waiter-facing UIs until multi-currency lands.
const String kCurrencySymbol = r'DH ';

/// Formats [amount] as a display price, e.g. `4.5 -> DH 4.50`.
String formatPrice(double amount) =>
    '$kCurrencySymbol${amount.toStringAsFixed(2)}';

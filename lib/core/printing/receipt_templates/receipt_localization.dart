/// Localized strings for printed receipts (§6 of improve.md — Option A).
///
/// Receipts print in a **fixed** language configured independently of the
/// till's UI language: the customer walking away with a paper copy has no
/// relationship to which language the staff set the app to. The choice lives
/// in [ReceiptLanguageController] and defaults to **French**.
///
/// This lookup is deliberately independent of `AppLocalizations`/`BuildContext`
/// — receipt generation can happen from background flows (order charge,
/// cash-out, refund) with no screen attached, so the templates resolve their
/// strings from the printer service's configured locale instead.
library;

/// The receipts' fixed language code, and the [ReceiptText] map for it.
const String defaultReceiptLocale = 'fr';

/// Every human-readable token the ESC/POS templates can emit, per language.
/// Kept ASCII-safe beyond the letters Latin-1 already encodes (see
/// `pos_support.posText`): accented Latin-1 characters print fine, characters
/// outside the page become `?`.
class ReceiptText {
  final String code;

  /// Brand tagline under the store name (client receipt + shift header).
  final String tagline;

  /// Prefix for the per-day order ticket number (`Order #` / `Commande n°`).
  final String orderPrefix;

  /// Kitchen ticket order headline (`ORDER` / `COMMANDE`).
  final String kitchenOrder;

  /// Full-width work header (`SHIFT REPORT` / `RAPPORT DE QUART`).
  final String shiftTitle;

  /// Interim-report banner ("preview, shift not closed").
  final String shiftBanner;

  /// `Orders made:`-style row label.
  final String ordersMade;

  /// `Total sales:` row label.
  final String totalSales;

  /// `Cash counted:` row label — the trailing spaces align the money column.
  final String cashCounted;

  /// `Cash variance:` row label.
  final String cashVariance;

  /// Refund receipt headline (`REFUND` / `REMBOURSEMENT`).
  final String refundTitle;

  /// `Original total:` row label.
  final String originalTotal;

  /// `Refunded:` row label.
  final String refunded;

  /// `Reason:` row label.
  final String reason;

  /// `Admin:` row label — trailing spaces align the value column.
  final String admin;

  /// `Printed <date>` footer prefix.
  final String printedPrefix;

  const ReceiptText({
    required this.code,
    required this.tagline,
    required this.orderPrefix,
    required this.kitchenOrder,
    required this.shiftTitle,
    required this.shiftBanner,
    required this.ordersMade,
    required this.totalSales,
    required this.cashCounted,
    required this.cashVariance,
    required this.refundTitle,
    required this.originalTotal,
    required this.refunded,
    required this.reason,
    required this.admin,
    required this.printedPrefix,
  });

  bool get isFrench => code == 'fr';

  /// `Order #007` / `Commande n° 007`.
  String orderNumber(String number) => '$orderPrefix$number';

  /// Kitchen headline with the padded ticket id: `ORDER #007` / `COMMANDE #007`.
  String kitchenOrderNumber(String number) => '$kitchenOrder $number';

  /// `Shift <start> to <end>` / `Quart du <start> au <end>`.
  String shiftRange(String start, String end) =>
      isFrench ? 'Quart du $start au $end' : 'Shift $start to $end';

  /// `Thank you for visiting <store>!` / `Merci de votre visite chez <store>!`
  String thanks(String store) =>
      isFrench ? 'Merci de votre visite chez $store !' : 'Thank you for visiting $store!';

  /// `Printed <date>` / `Imprimé le <date>`.
  String printed(String date) => '$printedPrefix $date';

  /// The sum total line, e.g. `TOTAL DH 18.00` (identical in both languages).
  String total(String amount) => 'TOTAL $amount';
}

/// English receipts.
const ReceiptText receiptTextEnglish = ReceiptText(
  code: 'en',
  tagline: 'Coffee · Drinks · Pastries',
  orderPrefix: 'Order #',
  kitchenOrder: 'ORDER',
  shiftTitle: 'SHIFT REPORT',
  shiftBanner: '*** PREVIEW - SHIFT NOT CLOSED ***',
  ordersMade: 'Orders made:   ',
  totalSales: 'Total sales:   ',
  cashCounted: 'Cash counted:  ',
  cashVariance: 'Cash variance: ',
  refundTitle: 'REFUND',
  originalTotal: 'Original total: ',
  refunded: 'Refunded: ',
  reason: 'Reason: ',
  admin: 'Admin:   ',
  printedPrefix: 'Printed',
);

/// French receipts (the default, per Option A).
const ReceiptText receiptTextFrench = ReceiptText(
  code: 'fr',
  tagline: 'Café · Boissons · Pâtisseries',
  orderPrefix: 'Commande n° ',
  kitchenOrder: 'COMMANDE',
  shiftTitle: 'RAPPORT DE QUART',
  shiftBanner: '*** APERÇU - CAISSE NON CLÔTURÉE ***',
  ordersMade: 'Commandes:      ',
  totalSales: 'Ventes totales: ',
  cashCounted: 'Espèces comptées:  ',
  cashVariance: 'Écart de caisse: ',
  refundTitle: 'REMBOURSEMENT',
  originalTotal: 'Total initial: ',
  refunded: 'Remboursé: ',
  reason: 'Motif: ',
  admin: 'Administrateur: ',
  printedPrefix: 'Imprimé le',
);

/// Resolves [ReceiptText] for a locale code ('en' or 'fr').
ReceiptText receiptTextFor(String locale) =>
    locale == 'en' ? receiptTextEnglish : receiptTextFrench;
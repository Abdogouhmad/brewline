import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:brewline/core/printing/receipt_templates/pos_support.dart';
import 'package:brewline/core/printing/receipt_templates/receipt_header.dart';
import 'package:brewline/core/printing/receipt_templates/receipt_localization.dart';

/// Everything the refund receipt needs, computed **before** calling the
/// template.
class RefundReceiptData {
  /// Original order total (before the refund), in cents.
  final int originalTotalCents;

  /// The amount refunded, in cents — printed as a **negative** figure
  /// (e.g. `-9.00`) per the spec.
  final int refundedCents;

  final String reason;
  final String adminName;

  /// Order ticket number (`#007`) or the raw order id when no per-day number.
  final int orderNumber;

  /// The order's unique ticket id.
  final int orderId;

  final DateTime at;

  const RefundReceiptData({
    required this.originalTotalCents,
    required this.refundedCents,
    required this.reason,
    required this.adminName,
    required this.orderNumber,
    required this.orderId,
    required this.at,
  });
}

/// The optional 88mm refund receipt printed after a successful refund.
///
/// Print is **never automatic** — the admin triggers it from the success state
/// (§5 step 5 of improve.md), since not every till correction needs a paper
/// copy. The refunded amount is the headline and is shown as a negative figure.
class RefundReceiptTemplate {
  final RefundReceiptData data;

  /// Receipt language code ('en' | 'fr'); the printer service passes the
  /// configured [ReceiptLanguage], defaulting to French per §6 Option A.
  final String locale;

  const RefundReceiptTemplate({
    required this.data,
    this.locale = defaultReceiptLocale,
  });

  /// Characters per line on an 88mm roll with font A — same measurement as the
  /// client receipt / shift report; verify against a physical test print.
  static const int lineWidth = 48;

  Future<List<int>> build() async {
    final strings = receiptTextFor(locale);
    final generator = await newPosGenerator(
      paper: PaperSize.mm80,
      lineWidth: lineWidth,
    );
    List<int> bytes = <int>[];

    bytes += await ReceiptHeader.append(generator, strings: strings);
    bytes += generator.text(
      strings.refundTitle,
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text(
      posText(strings.orderNumber(_orderNumber())),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      posDateTimeIn(locale, data.at),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    bytes += generator.text(
      posText(
        '${strings.originalTotal}'
        '${formatCentsPriceIn(locale, data.originalTotalCents)}',
      ),
    );
    bytes += generator.text(
      '${strings.refunded}${formatCentsPriceIn(locale, -data.refundedCents)}',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.hr();
    bytes += generator.text('${strings.reason}${posText(data.reason)}');
    bytes += generator.text('${strings.admin}${posText(data.adminName)}');
    bytes += generator.hr();

    bytes += generator.text(
      strings.printed(posDateTimeIn(locale, DateTime.now())),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();
    return bytes;
  }

  String _orderNumber() {
    final n = data.orderNumber;
    return n > 0 ? n.toString().padLeft(3, '0') : '${data.orderId}';
  }
}

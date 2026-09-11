import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/printing/receipt_templates/pos_support.dart';
import 'package:brewline/core/printing/receipt_templates/receipt_header.dart';
import 'package:brewline/core/printing/receipt_templates/receipt_localization.dart';

/// The 88mm receipt handed to the customer when an order is charged.
///
/// Printed in the configured receipt language ([locale], default French per
/// §6 Option A) — independent of the till's UI language.
class ClientReceiptTemplate {
  final OrderRecord order;

  /// Receipt language code ('en' | 'fr'); the printer service passes the
  /// configured [ReceiptLanguage], defaulting to French.
  final String locale;

  const ClientReceiptTemplate({
    required this.order,
    this.locale = defaultReceiptLocale,
  });

  /// Characters per line on an 88mm roll with font A. **Measure against a
  /// physical test print before trusting** — there is no 88mm preset in
  /// `esc_pos_utils_plus`, so the width is an explicit LINE_WIDTH, not a
  /// PaperSize enum value (see `pos_support.dart`).
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
      '${posText(ReceiptHeader.storeName)} - ${_orderNumber(strings)}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      posDateTimeIn(locale, order.createdAt),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    for (final item in order.items) {
      final line = '${item.quantity} x '
          '${posText(item.name)} '
          '${formatCentsPriceIn(locale, item.unitPriceCents)}';
      bytes += generator.text(line);
      // Line total is the quantity × unit price, right-aligned under the line.
      bytes += generator.text(
        '    ${formatCentsPriceIn(locale, item.totalCents)}',
        styles: const PosStyles(align: PosAlign.right),
      );
    }

    bytes += generator.hr();
    bytes += generator.text(
      strings.total(formatCentsPriceIn(locale, order.totalCents)),
      styles: const PosStyles(bold: true, align: PosAlign.right),
    );
    bytes += generator.feed(2);
    bytes += generator.text(
      posText(strings.thanks(ReceiptHeader.storeName)),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();
    return bytes;
  }

  String _orderNumber(ReceiptText strings) {
    final orderNumber = order.orderNumber;
    return orderNumber > 0
        ? strings.orderNumber(orderNumber.toString().padLeft(3, '0'))
        : strings.orderNumber(order.id.toString());
  }
}
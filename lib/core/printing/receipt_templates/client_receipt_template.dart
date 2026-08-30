import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/printing/receipt_templates/pos_support.dart';
import 'package:brewline/core/printing/receipt_templates/receipt_header.dart';

/// The 88mm receipt handed to the customer when an order is charged.
class ClientReceiptTemplate {
  final OrderRecord order;

  const ClientReceiptTemplate({required this.order});

  /// Characters per line on an 88mm roll with font A. **Measure against a
  /// physical test print before trusting** — there is no 88mm preset in
  /// `esc_pos_utils_plus`, so the width is an explicit LINE_WIDTH, not a
  /// PaperSize enum value (see `pos_support.dart`).
  static const int lineWidth = 48;

  Future<List<int>> build() async {
    final generator = await newPosGenerator(
      paper: PaperSize.mm80,
      lineWidth: lineWidth,
    );
    List<int> bytes = <int>[];

    bytes += await ReceiptHeader.append(generator);
    bytes += generator.text(
      '${posText(ReceiptHeader.storeName)} - ${_orderNumber()}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      posDateTime(order.createdAt),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    for (final item in order.items) {
      final line = '${item.quantity} x '
          '${posText(item.name)} '
          '${formatCentsPrice(_toCents(item.unitPrice))}';
      bytes += generator.text(line);
      // Line total is the quantity × unit price, right-aligned under the line.
      bytes += generator.text(
        '    ${formatCentsPrice(_lineTotal(item))}',
        styles: const PosStyles(align: PosAlign.right),
      );
    }

    bytes += generator.hr();
    bytes += generator.text(
      'TOTAL ${formatCentsPrice(_toCents(order.total))}',
      styles: const PosStyles(bold: true, align: PosAlign.right),
    );
    bytes += generator.feed(2);
    bytes += generator.text(
      'Thank you for visiting ${posText(ReceiptHeader.storeName)}!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();
    return bytes;
  }

  String _orderNumber() {
    final orderNumber = order.orderNumber;
    return orderNumber > 0
        ? 'Order #${orderNumber.toString().padLeft(3, '0')}'
        : 'Order #${order.id}';
  }

  static int _toCents(double value) => (value * 100).round();

  static int _lineTotal(OrderLineItem item) =>
      _toCents(item.quantity * item.unitPrice);
}
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/printing/receipt_templates/pos_support.dart';
import 'package:brewline/core/printing/receipt_templates/receipt_header.dart';

/// The 55mm ticket sent to the kitchen when an order is charged.
///
/// Kept deliberately compact — the kitchen wants the *what/how many* at a
/// glance, not the customer-facing branding — so it skips the shared
/// [ReceiptHeader] and leads with the order identity.
class KitchenTicketTemplate {
  final OrderRecord order;

  const KitchenTicketTemplate({required this.order});

  /// Characters per line on a 55mm roll with font A.
  ///
  /// **Measure before shipping:** this is the printable character count for
  /// this exact printer/font combination, not a guess fitted to a preset —
  /// `esc_pos_utils_plus` has no 55/88mm presets, so LINE_WIDTH is set
  /// explicitly (see `pos_support.dart`). Verify against a real 55mm test
  /// print before finalizing.
  static const int lineWidth = 32;

  Future<List<int>> build() async {
    final generator = await newPosGenerator(
      paper: PaperSize.mm58,
      lineWidth: lineWidth,
    );
    List<int> bytes = <int>[];

    bytes += generator.text(
      posText(ReceiptHeader.storeName),
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text(
      'ORDER ${_orderNumber()}',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text(
      posDateTime(order.createdAt),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    for (final item in order.items) {
      bytes += generator.text(
        '${item.quantity} x ${posText(item.name)}',
        maxCharsPerLine: lineWidth,
      );
    }

    bytes += generator.hr();
    bytes += generator.text(
      'TOTAL ${formatCentsPrice(_toCents(order.total))}',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();
    return bytes;
  }

  /// `#007` when the per-day counter was assigned, else the numeric ticket id.
  String _orderNumber() {
    final orderNumber = order.orderNumber;
    return orderNumber > 0
        ? '#${orderNumber.toString().padLeft(3, '0')}'
        : '#${order.id}';
  }

  static int _toCents(double value) => (value * 100).round();
}
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'pos_support.dart';

/// The café brand block shared by the client receipt and the shift report, so
/// every customer-facing print starts with the same header.
///
/// Kitchen tickets skip this (they're headed by the order itself instead).
class ReceiptHeader {
  const ReceiptHeader._();

  static const String storeName = 'BrewLine Café';

  /// Appends the brand block: bold centered store name, tagline and a full
  /// rule. Kept in one place so a rebrand is a one-line change.
  static Future<List<int>> append(Generator generator) async {
    List<int> bytes = <int>[];
    bytes += generator.text(
      posText(storeName),
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text(
      'Coffee · Drinks · Pastries',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();
    return bytes;
  }
}
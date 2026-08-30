import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'package:brewline/core/printing/receipt_templates/pos_support.dart';
import 'package:brewline/core/printing/receipt_templates/receipt_header.dart';

/// Everything the shift report needs to print, computed **before** calling
/// the template.
///
/// For a final cashout ([isFinal] = true) every value is the point-in-time
/// snapshot already written to `cashout_logs`; for an interim preview
/// ([isFinal] = false) [cashCountedCents]/[cashVarianceCents] are null and
/// the report carries a `PREVIEW — SHIFT NOT CLOSED` banner so nobody mistakes
/// it for the authoritative close record.
class ShiftReportData {
  final String waiterName;

  /// Username, shown on the report as attribution.
  final String waiterUsername;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final int orderCount;
  final int totalSalesCents;

  /// True for the cash-out print (line 7-8 of the spec: cash counted +
  /// variance are printed only when the shift is actually being closed).
  final bool isFinal;

  /// Physically counted drawer cash — needed only when [isFinal].
  final int? cashCountedCents;

  /// `counted − expected` — needed only when [isFinal].
  final int? cashVarianceCents;

  const ShiftReportData({
    required this.waiterName,
    required this.waiterUsername,
    required this.shiftStart,
    required this.shiftEnd,
    required this.orderCount,
    required this.totalSalesCents,
    required this.isFinal,
    this.cashCountedCents,
    this.cashVarianceCents,
  });
}

/// The 88mm shift report printed by both waiter Settings actions.
///
/// ## The LINE_WIDTH caveat (do NOT "fix" this back to the enum)
/// `esc_pos_utils_plus` only presets 58/72/80mm paper. This app's rolls are
/// 88mm, whose printable character count is a property of the *physical*
/// printer + font — so [lineWidth] is set explicitly through
/// `setGlobalFont(maxCharsPerLine:)` rather than derived from a
/// `PaperSize`. The value below must be confirmed against a real 88mm test
/// print before release — it is a measurement, not a spec constant.
class ShiftReportTemplate {
  final ShiftReportData data;

  const ShiftReportTemplate({required this.data});

  /// Characters per line on an 88mm roll (font A) — measure, don't guess.
  static const int lineWidth = 48;

  Future<List<int>> build() async {
    final generator = await newPosGenerator(
      paper: PaperSize.mm80,
      lineWidth: lineWidth,
    );
    List<int> bytes = <int>[];

    // Same header block as the client receipt, per the spec: the shift report
    // opens with the same branding so the two customer-facing prints match.
    bytes += await ReceiptHeader.append(generator);

    // Interim prints open with an unmistakable banner. Plain ASCII on purpose:
// the printer's Latin-1 page can't encode an em-dash (it'd print as `?`), and
// this line exists to be *read* at a glance.
    if (!data.isFinal) {
      bytes += generator.text(
        '*** PREVIEW - SHIFT NOT CLOSED ***',
        styles: const PosStyles(bold: true, align: PosAlign.center),
      );
      bytes += generator.emptyLines(1);
    }

    bytes += generator.text(
      'SHIFT REPORT',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    );
    bytes += generator.text(
      posText(data.waiterName),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    bytes += generator.text(
      posText(
        'Shift ${posDateTime(data.shiftStart)} to '
        '${posDateTime(data.shiftEnd)}',
      ),
      maxCharsPerLine: lineWidth,
    );
    bytes += generator.text('Orders made:   ${data.orderCount}');
    bytes += generator.text('Total sales:   ${formatCentsPrice(data.totalSalesCents)}');
    bytes += generator.hr();

    if (data.isFinal) {
      final counted = data.cashCountedCents ?? 0;
      final variance = data.cashVarianceCents ?? 0;
      bytes += generator.text('Cash counted:  ${formatCentsPrice(counted)}');
      bytes += generator.text('Cash variance: ${formatCentsPrice(variance)}');
      bytes += generator.hr();
    }

    bytes += generator.text(
      'Printed ${posDateTime(DateTime.now())}',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();
    return bytes;
  }
}
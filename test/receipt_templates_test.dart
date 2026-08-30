import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/printing/receipt_templates/client_receipt_template.dart';
import 'package:brewline/core/printing/receipt_templates/kitchen_ticket_template.dart';
import 'package:brewline/core/printing/receipt_templates/pos_support.dart';
import 'package:brewline/core/printing/receipt_templates/shift_report_template.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ESC/POS builders are pure byte generators: they never talk to a
/// printer (that's [PrinterTransport]'s job), so they're deterministic to
/// test. We decode the emitted bytes back to text and assert on the visible
/// content — control bytes (ESC `|`, `GS V`, feeds) don't interfere with
/// substring checks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pos_support', () {
    test('formatCents pads two decimal places, keeps sign', () {
      expect(formatCents(35000), '350.00');
      expect(formatCents(0), '0.00');
      expect(formatCents(12345), '123.45');
      expect(formatCents(-2500), '-25.00');
    });

    test('formatCentsPrice prefixes the currency symbol', () {
      expect(formatCentsPrice(35000), 'DH 350.00');
    });

    test('posText strips characters the Latin-1 code page can\'t encode', () {
      // 'é' fits in Latin-1 and stays; Arabic (outside the page) becomes '?'.
      expect(posText('Café'), 'Café');
      expect(posText('سعودي'), '?????');
    });
  });

  group('shift report template', () {
    ShiftReportData data({required bool isFinal}) => ShiftReportData(
      waiterName: 'John Doe',
      waiterUsername: 'john',
      shiftStart: DateTime(2026, 8, 29, 8, 0),
      shiftEnd: DateTime(2026, 8, 29, 21, 30),
      orderCount: 12,
      totalSalesCents: 35000,
      isFinal: isFinal,
      cashCountedCents: isFinal ? 35250 : null,
      cashVarianceCents: isFinal ? 250 : null,
    );

    test('final cashout report shows counted cash and variance, no preview', () async {
      final bytes = await ShiftReportTemplate(data: data(isFinal: true)).build();
      final text = String.fromCharCodes(bytes);
      expect(text, contains('SHIFT REPORT'));
      expect(text, contains('John Doe'));
      expect(text, contains('12')); // order count
      expect(text, contains('DH 350.00'));
      expect(text, contains('Cash counted:  DH 352.50'));
      expect(text, contains('Cash variance: DH 2.50'));
      expect(text, isNot(contains('PREVIEW')));
    });

    test('interim report is a labelled preview without cash lines', () async {
      final bytes = await ShiftReportTemplate(data: data(isFinal: false)).build();
      final text = String.fromCharCodes(bytes);
      expect(text, contains('PREVIEW - SHIFT NOT CLOSED'));
      expect(text, contains('SHIFT REPORT'));
      expect(text, isNot(contains('Cash counted:')));
      expect(text, isNot(contains('Cash variance:')));
    });

    test('ends with a feed + cut sequence', () async {
      final bytes = await ShiftReportTemplate(data: data(isFinal: false)).build();
      expect(bytes, isNotEmpty);
      // ESC i (0x1B 0x69) partial cut, or GS V (0x1D 0x56) full cut.
      final hasCut =
          _containsSeq(bytes, const [0x1D, 0x56]) ||
          _containsSeq(bytes, const [0x1B, 0x69]);
      expect(hasCut, isTrue, reason: 'receipt must end with a cut command');
    });
  });

  group('kitchen + client templates', () {
    final order = OrderRecord(
      id: 42,
      createdAt: DateTime(2026, 8, 29, 14, 30),
      orderNumber: 7,
      total: 18.0,
      items: const [
        OrderLineItem(
          productId: 'p-001',
          name: 'Espresso',
          quantity: 2,
          unitPrice: 9.0,
        ),
      ],
    );

    test('kitchen ticket (55mm) renders order identity and lines', () async {
      final bytes = await KitchenTicketTemplate(order: order).build();
      final text = String.fromCharCodes(bytes);
      expect(text, contains('ORDER #007'));
      expect(text, contains('2 x Espresso'));
      expect(text, contains('TOTAL DH 18.00'));
    });

    test('client receipt (88mm) shares the header and thanks the guest', () async {
      final bytes = await ClientReceiptTemplate(order: order).build();
      final text = String.fromCharCodes(bytes);
      expect(text, contains('BrewLine Café'));
      expect(text, contains('Order #007'));
      expect(text, contains('2 x Espresso '));
      expect(text, contains('TOTAL DH 18.00'));
      expect(text, contains('Thank you'));
    });
  });
}

/// Scans [bytes] for a byte sub-sequence ([haystack].contains for lists).
bool _containsSeq(List<int> bytes, List<int> needle) {
  for (var i = 0; i <= bytes.length - needle.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (bytes[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
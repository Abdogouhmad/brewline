import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/printing/receipt_templates/client_receipt_template.dart';
import 'package:brewline/core/printing/receipt_templates/kitchen_ticket_template.dart';
import 'package:brewline/core/printing/receipt_templates/pos_support.dart';
import 'package:brewline/core/printing/receipt_templates/refund_receipt_template.dart';
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

    test('formatCentsPriceIn places the symbol per locale', () {
      expect(formatCentsPriceIn('en', 35000), 'DH 350.00');
      expect(formatCentsPriceIn('fr', 35000), '350,00 DH');
      expect(formatCentsPriceIn('fr', -2500), '-25,00 DH');
      expect(formatCentsPriceIn('en', -2500), 'DH -25.00');
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
      final bytes = await ShiftReportTemplate(
        data: data(isFinal: true),
        locale: 'en',
      ).build();
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
      final bytes = await ShiftReportTemplate(
        data: data(isFinal: false),
        locale: 'en',
      ).build();
      final text = String.fromCharCodes(bytes);
      expect(text, contains('PREVIEW - SHIFT NOT CLOSED'));
      expect(text, contains('SHIFT REPORT'));
      expect(text, isNot(contains('Cash counted:')));
      expect(text, isNot(contains('Cash variance:')));
    });

    test('ends with a feed + cut sequence', () async {
      final bytes = await ShiftReportTemplate(
        data: data(isFinal: false),
        locale: 'en',
      ).build();
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
      totalCents: 1800,
      items: const [
        OrderLineItem(
          productId: 'p-001',
          name: 'Espresso',
          quantity: 2,
          unitPriceCents: 900,
        ),
      ],
    );

    test('kitchen ticket (55mm) renders order identity and lines', () async {
      final bytes = await KitchenTicketTemplate(
        order: order,
        locale: 'en',
      ).build();
      final text = String.fromCharCodes(bytes);
      expect(text, contains('ORDER #007'));
      expect(text, contains('2 x Espresso'));
      expect(text, contains('TOTAL DH 18.00'));
    });

    test('client receipt (88mm) shares the header and thanks the guest', () async {
      final bytes = await ClientReceiptTemplate(
        order: order,
        locale: 'en',
      ).build();
      final text = String.fromCharCodes(bytes);
      expect(text, contains('BrewLine Café'));
      expect(text, contains('Order #007'));
      expect(text, contains('2 x Espresso '));
      expect(text, contains('TOTAL DH 18.00'));
      expect(text, contains('Thank you'));
    });
  });

  group('French receipts (§6 Option A default)', () {
    final order = OrderRecord(
      id: 42,
      createdAt: DateTime(2026, 8, 29, 14, 30),
      orderNumber: 7,
      totalCents: 1800,
      items: const [
        OrderLineItem(
          productId: 'p-001',
          name: 'Espresso',
          quantity: 2,
          unitPriceCents: 900,
        ),
      ],
    );
    final data = ShiftReportData(
      waiterName: 'John Doe',
      waiterUsername: 'john',
      shiftStart: DateTime(2026, 8, 29, 8, 0),
      shiftEnd: DateTime(2026, 8, 29, 21, 30),
      orderCount: 12,
      totalSalesCents: 35000,
      isFinal: true,
      cashCountedCents: 35250,
      cashVarianceCents: 250,
    );

    test('default locale is French even for the kitchen/client receipts', () async {
      // Constructing without a locale must yield French (Option A default).
      final client = String.fromCharCodes(
        await ClientReceiptTemplate(order: order).build(),
      );
      expect(client, contains('Commande n° 007'));
      expect(client, contains('TOTAL 18,00 DH'));
      expect(client, contains('Merci de votre visite chez BrewLine Café !'));
      expect(client, contains('29 août 2026 14:30')); // French month name

      final kitchen = String.fromCharCodes(
        await KitchenTicketTemplate(order: order).build(),
      );
      expect(kitchen, contains('COMMANDE #007'));
      expect(kitchen, contains('TOTAL 18,00 DH'));
    });

    test('shift report prints French labels and amounts', () async {
      final text = String.fromCharCodes(
        await ShiftReportTemplate(data: data).build(), // default French
      );
      expect(text, contains('RAPPORT DE QUART'));
      expect(text, contains('Quart du 29 août 2026 08:00 au 29 août 2026 21:30'));
      expect(text, contains('Espèces comptées:  352,50 DH'));
      expect(text, contains('Écart de caisse: 2,50 DH'));
      expect(text, contains('Imprimé le'));
    });

    test('refund receipt prints French labels', () async {
      final text = String.fromCharCodes(
        await RefundReceiptTemplate(
          data: RefundReceiptData(
            originalTotalCents: 1800,
            refundedCents: 900,
            reason: 'wrong order',
            adminName: 'Admin',
            orderNumber: 7,
            orderId: 42,
            at: DateTime(2026, 8, 29, 15, 0),
          ),
        ).build(),
      );
      expect(text, contains('REMBOURSEMENT'));
      expect(text, contains('Commande n° 007'));
      expect(text, contains('Total initial: 18,00 DH'));
      expect(text, contains('Remboursé: -9,00 DH'));
      expect(text, contains('Motif: wrong order'));
      expect(text, contains('Administrateur: Admin'));
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
/// The single door into printing for the whole app.
///
/// ## Transport-agnostic design
/// Callers (order charge flow, waiter Settings actions) only ever touch this
/// service — they never see a socket, a plugin, or a `PrinterTransport`.
/// The service resolves the configured transport at call time from
/// [PrinterSettings], builds the right ESC/POS byte sequence with the
/// `*_template.dart` builders, and sends it. Swapping USB for network (or the
/// inverse) is a settings change, not a code change.
///
/// ## Why network is a raw socket but USB is a plugin
/// Network (Ethernet/RJ45) thermal printers listen for raw ESC/POS bytes on
/// TCP 9100 — Dart's built-in `dart:io` `Socket` does that natively, with no
/// native code and identical behaviour on every platform. USB printing, by
/// contrast, needs Android's USB Host API (enumeration, permission grants,
/// bulk transfers), which only exists via a native plugin. Do not "simplify"
/// both transports into one package: it would drag native code onto the
/// network path for zero benefit. Receipt bytes come from `esc_pos_utils_plus`
/// purely as a *builder* — it never touches the wire itself.
///
/// Every failure surfaces as a typed [PrinterOfflineException] or
/// [PrinterTimeoutException], never a raw socket/crash.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/printing/network_printer_transport.dart';
import 'package:brewline/core/printing/printer_settings.dart';
import 'package:brewline/core/printing/printer_transport.dart';
import 'package:brewline/core/printing/receipt_templates/client_receipt_template.dart';
import 'package:brewline/core/printing/receipt_templates/kitchen_ticket_template.dart';
import 'package:brewline/core/printing/receipt_templates/refund_receipt_template.dart';
import 'package:brewline/core/printing/receipt_templates/shift_report_template.dart';
import 'package:brewline/core/printing/usb_printer_transport.dart';

/// Wraps [PrinterSettings] into the two concrete transports so callers can
/// keep using the same interface whichever wire is configured.
class ReceiptPrinterService {
  final PrinterSettings settings;

  const ReceiptPrinterService(this.settings);

  /// The transport matching the current [PrinterSettings] — resolved on every
  /// call so a mid-session settings change takes effect without a restart.
  PrinterTransport _transport() => settings.connectionType ==
          PrinterConnectionType.network
      ? NetworkPrinterTransport(host: settings.ipAddress, port: settings.port)
      : const UsbPrinterTransport();

  /// Kitchen ticket (55mm). Print when an order is charged.
  Future<void> printKitchenTicket(OrderRecord order) async {
    final bytes = await KitchenTicketTemplate(order: order).build();
    await _transport().send(bytes);
  }

  /// Customer receipt (88mm). Print when an order is charged.
  Future<void> printClientReceipt(OrderRecord order) async {
    final bytes = await ClientReceiptTemplate(order: order).build();
    await _transport().send(bytes);
  }

  /// Shift report (88mm) for a final cash-out *or* an interim preview — the
  /// report itself tells the printer apart via [ShiftReportData.isFinal].
  Future<void> printShiftReport(ShiftReportData data) async {
    final bytes = await ShiftReportTemplate(data: data).build();
    await _transport().send(bytes);
  }

  /// Refund receipt (88mm) — printed only when explicitly requested after a
  /// refund, never automatically.
  Future<void> printRefundReceipt(RefundReceiptData data) async {
    final bytes = await RefundReceiptTemplate(data: data).build();
    await _transport().send(bytes);
  }

  /// Cheap reachability probe for the UI's "Printer not reachable" message.
  Future<bool> isConnected() => _transport().isConnected();
}

/// A service bound to the *latest* printer settings: [Provider] watches
/// [printerSettingsProvider], so `ref.read` at any call site gets a service
/// whose transport already reflects the current wiring (admin edits take
/// effect without an app restart, per the acceptance checklist).
final receiptPrinterServiceProvider = Provider<ReceiptPrinterService>((ref) {
  return ReceiptPrinterService(ref.watch(printerSettingsProvider));
});
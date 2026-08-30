import 'dart:async';
import 'dart:io';

import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:brewline/core/printing/printer_transport.dart';

/// Sends ESC/POS bytes to a USB-attached thermal printer (Android USB Host
/// API, Windows).
///
/// ## Why this needs a plugin while network printing doesn't
/// USB printing requires the Android USB Host API (bus enumeration,
/// permission grants, bulk transfers) — a native capability a Dart `Socket`
/// can never reach. The transport behind this class therefore delegates to
/// `flutter_pos_printer_platform_image_3`, whose plugin wraps exactly that.
/// Network printing uses a bare TCP socket instead (see
/// [NetworkPrinterTransport]); forcing both transports through one plugin
/// would add a needless native dependency to the network path, so don't
/// "simplify" them together.
///
/// On platforms the plugin doesn't support (Linux/macOS/iOS) [send] throws
/// [PrinterOfflineException]; the UI then shows "Printer not reachable"
/// rather than crashing.
class UsbPrinterTransport implements PrinterTransport {
  final Duration timeout;

  const UsbPrinterTransport({this.timeout = kPrinterSendTimeout});

  /// The plugin only ships USB support for Android (USB Host) and Windows
  /// (spooler). Everywhere else USB printing is simply unavailable.
  static bool get _supported => Platform.isAndroid || Platform.isWindows;

  @override
  Future<void> send(List<int> bytes) async {
    if (!_supported) {
      throw PrinterOfflineException(
        'USB printing is only available on Android and Windows '
        '(this build runs on ${Platform.operatingSystem}).',
      );
    }

    final device = await _discoverFirst();
    final connected = await PrinterManager.instance
        .connect(
          type: PrinterType.usb,
          model: UsbPrinterInput(
            name: device.name,
            vendorId: device.vendorId,
            productId: device.productId,
          ),
        )
        .timeout(timeout, onTimeout: () => false);
    if (!connected) {
      throw const PrinterOfflineException(
        'USB printer refused the connection.',
      );
    }

    try {
      final sent = await PrinterManager.instance
          .send(type: PrinterType.usb, bytes: bytes)
          .timeout(timeout, onTimeout: () => false);
      if (!sent) {
        throw const PrinterOfflineException('USB printer didn\'t send bytes.');
      }
    } finally {
      await PrinterManager.instance
          .disconnect(type: PrinterType.usb)
          .catchError((_) => false);
    }
  }

  @override
  Future<bool> isConnected() async {
    if (!_supported) return false;
    try {
      await _discoverFirst();
      return true;
    } on PrinterException {
      return false;
    }
  }

  /// First USB printer the OS reports currently attached. A bare
  /// `discovery()` stream that never yields a device times out and becomes a
  /// "no printer found" offline error rather than hanging.
  Future<PrinterDevice> _discoverFirst() async {
    try {
      return await PrinterManager.instance
          .discovery(type: PrinterType.usb)
          .first
          .timeout(timeout);
    } on TimeoutException {
      throw const PrinterOfflineException('No USB printer found.');
    } on PrinterException {
      rethrow;
    } catch (e) {
      throw PrinterOfflineException('USB discovery failed: $e');
    }
  }
}
import 'dart:async';
import 'dart:io';

import 'package:brewline/core/printing/printer_transport.dart';

/// Sends ESC/POS bytes to a network (Ethernet/RJ45) thermal printer over a
/// raw TCP socket on port 9100.
///
/// ## Why a raw socket and not a plugin
/// JetDirect-style network printers universally listen for raw ESC/POS bytes
/// on TCP 9100 — no discovery, no negotiation, no driver. Dart's built-in
/// `dart:io` `Socket` is therefore both *simpler* and *more reliable* than a
/// plugin for this case, and it works identically on Android and desktop with
/// zero native code. A plugin would only add an abstraction on top of
/// something the language already does natively. Do not "simplify" by routing
/// network printing through the USB plugin — the two transports exist because
/// their underlying mechanisms are genuinely different.
class NetworkPrinterTransport implements PrinterTransport {
  /// IP or hostname of the printer.
  final String host;

  /// TCP port — 9100 is the RAW/JetDirect default; editable for printers that
  /// listen elsewhere.
  final int port;

  final Duration timeout;

  const NetworkPrinterTransport({
    required this.host,
    this.port = 9100,
    this.timeout = kPrinterSendTimeout,
  });

  @override
  Future<void> send(List<int> bytes) async {
    if (host.trim().isEmpty) {
      throw const PrinterOfflineException('No printer IP address configured.');
    }
    final socket = await _connect();
    try {
      socket.add(bytes);
      await socket.flush().timeout(timeout, onTimeout: () {
        throw const PrinterTimeoutException('Printer didn\'t acknowledge bytes.');
      });
    } on SocketException catch (e) {
      throw PrinterOfflineException('Socket write failed: ${e.message}');
    } finally {
      // Best-effort close that can never mask the error the try/catch above is
      // about to surface: on a timed-out flush the socket is mid-close and
      // `close()` may throw synchronously (StateError), so swallow everything.
      try {
        await socket.close().catchError((_) {});
      } catch (_) {
        socket.destroy();
      }
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      final socket = await _connect();
      await socket.close();
      return true;
    } on PrinterException {
      return false;
    }
  }

  /// Opens (and returns) a connected socket, mapping failures to typed
  /// errors so callers never see a bare [SocketException].
  Future<Socket> _connect() async {
    try {
      return await Socket.connect(host, port).timeout(timeout, onTimeout: () {
        throw const PrinterTimeoutException(
          'Timed out connecting to the printer.',
        );
      });
    } on SocketException catch (e) {
      throw PrinterOfflineException(
        'Couldn\'t reach the printer at $host:$port (${e.message}).',
      );
    }
  }
}
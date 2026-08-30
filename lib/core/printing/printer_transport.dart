/// The wire-level abstraction between receipt code and any real printer.
///
/// Receipt building ([ReceiptPrinterService] + the `*_template.dart` files)
/// only ever talks to [PrinterTransport]. It never knows — or cares —
/// whether the printer is plugged in over USB or reachable over the network,
/// which mirrors the project's transport-agnostic service-interface pattern.
library;

import 'dart:async';

/// How long a single send/connect probe may take before it's reported as a
/// timeout. Kept short on purpose: a POS should never hang a waiter's flow
/// waiting on a dead printer.
const Duration kPrinterSendTimeout = Duration(seconds: 5);

/// Base class of every printer connection.
abstract class PrinterTransport {
  const PrinterTransport();

  /// Prints raw ESC/POS [bytes] to the device.
  ///
  /// Guarantees typed failures — the underlying socket/plugin exceptions are
  /// never allowed to leak, so a caller can catch [PrinterOfflineException]
  /// (unreachable, disconnected, or unsupported on this platform) and
  /// [PrinterTimeoutException] (hung) without poking at internals.
  Future<void> send(List<int> bytes);

  /// Cheap probe used to pre-check reachability before printing. `true` only
  /// when a printer is actually reachable right now.
  Future<bool> isConnected();
}

/// Catch-all for every typed printer failure ([PrinterOfflineException] /
/// [PrinterTimeoutException]) — used by reachability probes to treat both as
/// "cannot print right now" without case analysis.
abstract class PrinterException implements Exception {
  String get message;
}

/// The printer is unreachable: no device, connection refused, bytes failed to
/// write, or the transport isn't available on this platform.
class PrinterOfflineException implements PrinterException {
  @override
  final String message;

  const PrinterOfflineException(this.message);

  @override
  String toString() => 'PrinterOfflineException: $message';
}

/// A socket/plugin call blew past [kPrinterSendTimeout].
class PrinterTimeoutException implements PrinterException {
  @override
  final String message;

  const PrinterTimeoutException(this.message);

  @override
  String toString() => 'PrinterTimeoutException: $message';
}

/// How a physically attached printer is wired to the terminal. One printer
/// handles all receipt types, so this is a single device-level choice, not a
/// per-receipt one.
enum PrinterConnectionType {
  usb,
  network;

  /// `'usb'` / `'network'` — the persisted value in SharedPreferences.
  String get storageValue => name;

  static PrinterConnectionType? fromStorage(String? value) =>
      values.asNameMap()[value];
}
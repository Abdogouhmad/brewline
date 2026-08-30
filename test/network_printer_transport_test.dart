import 'dart:async';
import 'dart:io';

import 'package:brewline/core/printing/network_printer_transport.dart';
import 'package:brewline/core/printing/printer_transport.dart';
import 'package:flutter_test/flutter_test.dart';

/// Network transport tests spin up a real `ServerSocket` on a loopback port to
/// emulate a JetDirect printer's RAW listener — a local proxy for §8's
/// "test against a real printer" without any hardware.
void main() {
  test('send() delivers the exact bytes over TCP', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close());

    final received = Completer<List<int>>();
    server.listen((socket) async {
      final buffer = <int>[];
      await for (final chunk in socket) {
        buffer.addAll(chunk);
      }
      if (!received.isCompleted) received.complete(buffer);
      socket.destroy();
    });

    final expected = List<int>.generate(64, (i) => i);
    final transport = NetworkPrinterTransport(
      host: '127.0.0.1',
      port: server.port,
    );
    await transport.send(expected);

    expect(await received.future, expected);
  });

  test('isConnected() is true against a listening printer', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close());
    server.listen((_) {});

    final transport = NetworkPrinterTransport(
      host: '127.0.0.1',
      port: server.port,
    );
    expect(await transport.isConnected(), isTrue);
  });

  test('connection refused surfaces as PrinterOfflineException', () async {
    // Grab a port, then free it — nothing listens there anymore.
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();

    final transport = NetworkPrinterTransport(
      host: '127.0.0.1',
      port: port,
    );
    await expectLater(transport.send(const [0x1B]), throwsA(isA<PrinterOfflineException>()));
    expect(await transport.isConnected(), isFalse);
  });

  test('an unresponsive peer that never reads triggers PrinterTimeoutException',
      () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close());
    // Accept connections but never read: the peer's window stays closed, so
    // the sender's flush blocks once buffers fill up.
    server.listen((socket) {});

    // 16 MB is far beyond both sockets' buffers → the write must stall and
    // trip the caller-side timeout.
    final payload = List<int>.filled(16 * 1024 * 1024, 0x1B);
    final transport = NetworkPrinterTransport(
      host: '127.0.0.1',
      port: server.port,
      timeout: const Duration(milliseconds: 200),
    );
    await expectLater(
      transport.send(payload),
      throwsA(isA<PrinterTimeoutException>()),
    );
  });

  test('an empty host is an offline error, not a socket error', () async {
    const transport = NetworkPrinterTransport(host: '  ', port: 9100);
    await expectLater(
      transport.send(const [0x1B]),
      throwsA(isA<PrinterOfflineException>()),
    );
  });
}
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/printing/printer_transport.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

/// Device-level printer configuration.
///
/// A printer is physically attached to one terminal, so unlike the per-waiter
/// receipt toggles this setting is shared by the whole device (admin-edited,
/// waiter-relevant). One transport handles **all** receipt types — kitchen,
/// client and shift report — per the "one printer, three receipts"
/// assumption; a second physical printer would need a second transport config.
class PrinterSettings {
  /// Over what wire the receipt bytes travel.
  final PrinterConnectionType connectionType;

  /// Target IP/hostname when [connectionType] is [PrinterConnectionType.network].
  final String ipAddress;

  /// Raw ESC/POS TCP port; 9100 (JetDirect) is the universal default.
  final int port;

  const PrinterSettings({
    required this.connectionType,
    required this.ipAddress,
    required this.port,
  });

  /// A new terminal is configured as USB by default (no address to pre-fill).
  static const defaults = PrinterSettings(
    connectionType: PrinterConnectionType.usb,
    ipAddress: '',
    port: 9100,
  );

  PrinterSettings copyWith({
    PrinterConnectionType? connectionType,
    String? ipAddress,
    int? port,
  }) => PrinterSettings(
    connectionType: connectionType ?? this.connectionType,
    ipAddress: ipAddress ?? this.ipAddress,
    port: port ?? this.port,
  );
}

/// Persists printer settings under three flat SharedPreferences keys (small
/// enough that a dedicated table isn't warranted).
class PrinterSettingsController extends Notifier<PrinterSettings> {
  static const _typeKey = 'printer_connection_type';
  static const _ipKey = 'printer_ip';
  static const _portKey = 'printer_port';

  @override
  PrinterSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return PrinterSettings(
      connectionType:
          PrinterConnectionType.fromStorage(prefs.getString(_typeKey)) ??
          PrinterSettings.defaults.connectionType,
      ipAddress: prefs.getString(_ipKey) ?? PrinterSettings.defaults.ipAddress,
      port: prefs.getInt(_portKey) ?? PrinterSettings.defaults.port,
    );
  }

  Future<void> setConnectionType(PrinterConnectionType type) async {
    state = state.copyWith(connectionType: type);
    await ref.read(sharedPreferencesProvider).setString(_typeKey, type.storageValue);
  }

  /// Saves the network target (only meaningful for the network transport, but
  /// harmless to persist early so the fields aren't lost mid-edit).
  Future<void> setNetworkAddress({required String ipAddress, required int port}) async {
    state = state.copyWith(ipAddress: ipAddress.trim(), port: port);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_ipKey, ipAddress.trim());
    await prefs.setInt(_portKey, port);
  }
}

final printerSettingsProvider =
    NotifierProvider<PrinterSettingsController, PrinterSettings>(
      PrinterSettingsController.new,
    );
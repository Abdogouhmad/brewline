import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/printing/printer_settings.dart';
import 'package:brewline/core/printing/printer_transport.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_section_card.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Device-level printer configuration (§1.3 of the improve spec) — the
/// single setting that chooses which [PrinterTransport] every receipt goes
/// through (USB vs a network printer on TCP 9100).
///
/// This is admin-only and applies to the whole terminal: a printer is
/// physically attached to one device, so it is not a per-waiter preference.
/// Field edits persist immediately through [printerSettingsProvider] (no save
/// button), so `receiptPrinterServiceProvider` picks up a transport change
/// without restarting the app.
class PrinterSettingsSection extends ConsumerStatefulWidget {
  const PrinterSettingsSection({super.key});

  @override
  ConsumerState<PrinterSettingsSection> createState() =>
      _PrinterSettingsSectionState();
}

class _PrinterSettingsSectionState extends ConsumerState<PrinterSettingsSection> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(printerSettingsProvider);
    _ipController = TextEditingController(text: settings.ipAddress);
    _portController = TextEditingController(text: '${settings.port}');
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _saveNetwork() async {
    final port = int.tryParse(_portController.text.trim());
    if (port == null || port < 1 || port > 65535) {
      showUiSnackBar(
        context,
        'Port must be a number between 1 and 65535',
        type: UiSnackBarType.error,
      );
      return;
    }
    await ref.read(printerSettingsProvider.notifier).setNetworkAddress(
      ipAddress: _ipController.text,
      port: port,
    );
    if (!mounted) return;
    showUiSnackBar(
      context,
      'Printer settings saved',
      type: UiSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printerSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isNetwork = settings.connectionType == PrinterConnectionType.network;

    return SettingsSectionCard(
      icon: Icons.print_rounded,
      title: 'Printer',
      subtitle: 'Which receipt printer this terminal uses',
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.sm, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<PrinterConnectionType>(
                segments: const [
                  ButtonSegment(
                    value: PrinterConnectionType.usb,
                    label: Text('USB'),
                    icon: Icon(Icons.usb_rounded),
                  ),
                  ButtonSegment(
                    value: PrinterConnectionType.network,
                    label: Text('Network'),
                    icon: Icon(Icons.wifi_rounded),
                  ),
                ],
                selected: {settings.connectionType},
                onSelectionChanged: (selection) {
                  ref
                      .read(printerSettingsProvider.notifier)
                      .setConnectionType(selection.first);
                },
              ),
              SizedBox(height: Space.lg),
              if (isNetwork) ...[
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP address',
                    hintText: '192.168.1.50',
                    prefixIcon: Icon(Icons.lan_outlined),
                  ),
                ),
                SizedBox(height: Space.lg),
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    helperText:
                        'Raw ESC/POS port (default 9100, JetDirect)',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                ),
                SizedBox(height: Space.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saveNetwork,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ] else
                UiText(
                  'The USB printer is detected automatically. Switch to '
                  'Network to set an address.',
                  type: UiTextType.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
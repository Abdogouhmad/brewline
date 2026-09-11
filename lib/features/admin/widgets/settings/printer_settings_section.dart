import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/localization/receipt_language_controller.dart';
import 'package:brewline/core/printing/printer_settings.dart';
import 'package:brewline/core/printing/printer_transport.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/widgets/settings/settings_section_card.dart';
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

class _PrinterSettingsSectionState
    extends ConsumerState<PrinterSettingsSection> {
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
        AppLocalizations.of(context)!.printerInvalidPort,
        type: UiSnackBarType.error,
      );
      return;
    }
    await ref
        .read(printerSettingsProvider.notifier)
        .setNetworkAddress(ipAddress: _ipController.text, port: port);
    if (!mounted) return;
    showUiSnackBar(
      context,
      AppLocalizations.of(context)!.printerSaved,
      type: UiSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(printerSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isNetwork = settings.connectionType == PrinterConnectionType.network;
    final l10n = AppLocalizations.of(context)!;

    return SettingsSectionCard(
      titleHeader: l10n.settingsHardware,
      icon: Icons.print_rounded,
      title: l10n.printerTitle,
      subtitle: l10n.printerSubtitle,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Space.sm, Space.sm, Space.sm, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<PrinterConnectionType>(
                segments: [
                  ButtonSegment(
                    value: PrinterConnectionType.usb,
                    label: Text(l10n.printerUsb),
                    icon: const Icon(Icons.usb_rounded),
                  ),
                  ButtonSegment(
                    value: PrinterConnectionType.network,
                    label: Text(l10n.printerNetwork),
                    icon: const Icon(Icons.wifi_rounded),
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
              DropdownButtonFormField<ReceiptLanguage>(
                initialValue: ref.watch(receiptLanguageProvider),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.printerReceiptLanguageLabel,
                  helperText: l10n.printerReceiptLanguageHelper,
                  prefixIcon: const Icon(Icons.translate_rounded),
                ),
                items: [
                  for (final language in ReceiptLanguage.values)
                    DropdownMenuItem(
                      value: language,
                      child: Text(language.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(receiptLanguageProvider.notifier)
                        .setLanguage(value);
                  }
                },
              ),
              SizedBox(height: Space.lg),
              if (isNetwork) ...[
                TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: l10n.printerIpAddress,
                    hintText: l10n.printerIpHint,
                    prefixIcon: const Icon(Icons.lan_outlined),
                  ),
                ),
                SizedBox(height: Space.lg),
                TextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.printerPort,
                    helperText: l10n.printerPortHelper,
                    prefixIcon: const Icon(Icons.numbers_rounded),
                  ),
                ),
                SizedBox(height: Space.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saveNetwork,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.printerSave),
                  ),
                ),
              ] else
                UiText(
                  l10n.printerUsbInfo,
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

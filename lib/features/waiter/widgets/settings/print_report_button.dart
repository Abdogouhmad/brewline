import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/printing/printer_transport.dart';
import 'package:brewline/core/printing/receipt_printer_service.dart';
import 'package:brewline/core/printing/receipt_templates/shift_report_template.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/repositories/cashout_repository.dart';
import 'package:brewline/features/auth/providers/current_user_provider.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_tile.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';

/// The interim "Print Report" action — a live preview of the current shift,
/// **without** closing it (§2.1 interim variant + §3.2 of the spec).
///
/// * No confirm dialog: nothing is closed or changed.
/// * Prints the shift report with the `PREVIEW — SHIFT NOT CLOSED` banner and
///   **no** cash-counted/variance lines.
/// * Logs a `report_print` audit event instead of writing to `cashout_logs` —
///   the shift is still open so a ledger row now would be a lie that the admin
///   Cashout Logs screen would show as authoritative.
/// * No navigation: the waiter stays on Settings.
class PrintReportButton extends ConsumerStatefulWidget {
  const PrintReportButton({super.key});

  @override
  ConsumerState<PrintReportButton> createState() => _PrintReportButtonState();
}

class _PrintReportButtonState extends ConsumerState<PrintReportButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: Icons.print_rounded,
      title: 'Print report',
      subtitle: 'Print a preview of your shift, without closing it',
      onTap: _busy ? null : _printPreview,
    );
  }

  Future<void> _printPreview() async {
    setState(() => _busy = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;

      final cashout = await ref.read(cashoutRepositoryProvider.future);
      final summary =
          await cashout.currentShiftSummary(waiterUsername: user.username);
      final report = ShiftReportData(
        waiterName: user.name,
        waiterUsername: user.username,
        shiftStart: summary.shiftStart,
        shiftEnd: summary.shiftEnd,
        orderCount: summary.orderCount,
        totalSalesCents: summary.totalSalesCents,
        isFinal: false,
      );

      // Print first, then note the attempt on the audit stream whether or not
      // the printer was reachable — reprint frequency is the fraud signal this
      // event feeds, and an attempted-but-failed print is still a print event.
      try {
        await ref
            .read(receiptPrinterServiceProvider)
            .printShiftReport(report);
      } on PrinterException catch (e) {
        if (mounted) {
          showUiSnackBar(
            context,
            'Couldn\'t print the report — check the printer (${e.message})',
            type: UiSnackBarType.error,
          );
        }
      } finally {
        final audit = await ref.read(auditRepositoryProvider.future);
        await audit.logEvent(
          eventType: 'report_print',
          actor: user.username,
          metadata: '{"orderCount":${summary.orderCount},'
              '"totalSalesCents":${summary.totalSalesCents}}',
        );
      }

      if (!mounted) return;
      showUiSnackBar(
        context,
        summary.orderCount == 0
            ? 'No orders yet — the report is a placeholder'
            : 'Report sent to the printer — shift still open',
        type: UiSnackBarType.success,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
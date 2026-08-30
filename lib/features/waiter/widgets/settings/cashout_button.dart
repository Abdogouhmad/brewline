import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/cashout_record.dart';
import 'package:brewline/core/printing/printer_transport.dart';
import 'package:brewline/core/printing/receipt_printer_service.dart';
import 'package:brewline/core/printing/receipt_templates/shift_report_template.dart';
import 'package:brewline/core/repositories/cashout_repository.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/auth/providers/current_user_provider.dart';
import 'package:brewline/features/auth/login_page.dart';
import 'package:brewline/features/waiter/widgets/settings/settings_tile.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// The final "Cash Out & Print Report" action (§3.1 of the spec) — the one
/// that closes the shift.
///
/// Flow: confirm (irreversible!) → prompt cash counted → write the single
/// `cashout_logs` row + `cashout` audit event (the derived shift close) →
/// print the final 88mm report → log out.
///
/// ## Printer failures never lose a cashout
/// [CashoutRepository.logCashout] runs *first*. If printing then fails the
/// ledger row still stands (step 9 of the spec: the cashout must never depend
/// on the printer) — the user gets a "Report saved, but printing failed"
/// message with a retry-print action **before** being logged out.
class CashoutButton extends ConsumerStatefulWidget {
  const CashoutButton({super.key});

  @override
  ConsumerState<CashoutButton> createState() => _CashoutButtonState();
}

class _CashoutButtonState extends ConsumerState<CashoutButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: Icons.point_of_sale_rounded,
      title: 'Cash out & print report',
      subtitle: 'Close the shift, print a sales summary, and sign out',
      onTap: _busy ? null : _cashout,
    );
  }

  Future<void> _cashout() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await _confirmClose(context);
      if (confirmed != true) return;

      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;

      final cashout = await ref.read(cashoutRepositoryProvider.future);
      final summary =
          await cashout.currentShiftSummary(waiterUsername: user.username);
      if (!mounted) return;

      final countedCents = await _askCashCounted(
        context,
        expectedCents: summary.totalSalesCents,
      );
      if (countedCents == null) return; // Cancelled — shift stays open.

      final now = DateTime.now();
      final record = CashoutRecord(
        waiterId: user.id,
        waiterUsername: user.username,
        waiterName: user.name,
        shiftStart: summary.shiftStart,
        shiftEnd: summary.shiftEnd,
        orderCount: summary.orderCount,
        totalSalesCents: summary.totalSalesCents,
        cashCountedCents: countedCents,
        cashVarianceCents: countedCents - summary.totalSalesCents,
        createdAt: now,
      );

      // 1. Finalize the close — the authoritative write (§3.1 steps 3–6).
      await cashout.logCashout(record);

      // 2. Print the final report. Feedbacks can fail without touching the
      //    ledger; a failure must never block the cashout itself.
      final report = ShiftReportData(
        waiterName: record.waiterName,
        waiterUsername: record.waiterUsername,
        shiftStart: record.shiftStart,
        shiftEnd: record.shiftEnd,
        orderCount: record.orderCount,
        totalSalesCents: record.totalSalesCents,
        isFinal: true,
        cashCountedCents: record.cashCountedCents,
        cashVarianceCents: record.cashVarianceCents,
      );

      bool printed = true;
      try {
        await ref.read(receiptPrinterServiceProvider).printShiftReport(report);
      } on PrinterException catch (e) {
        printed = false;
        if (mounted) {
          showUiSnackBar(
            context,
            'Shift closed, but the report couldn\'t print — check the printer '
            '(${e.message})',
            type: UiSnackBarType.error,
            label: 'Retry',
            onLabelPressed: () => _retryPrint(report),
          );
        }
      }

      if (printed && mounted) {
        showUiSnackBar(
          context,
          'Shift closed — report sent to the printer',
          type: UiSnackBarType.success,
        );
      }

      // 3. Sign out — reusing the pushed-login-page logout so the session
      //    really ends (the user already confirmed this in step 1).
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Re-attempts the final report print from the logout flow's retry action.
  /// Never throws — the outcome is surfaced as a snackbar (which outlives the
  /// Settings route, since it rides the app-level messenger).
  Future<void> _retryPrint(ShiftReportData report) async {
    try {
      await ref.read(receiptPrinterServiceProvider).printShiftReport(report);
      if (mounted) {
        showUiSnackBar(
          context,
          'Report printed',
          type: UiSnackBarType.success,
        );
      }
    } on PrinterException catch (e) {
      if (mounted) {
        showUiSnackBar(
          context,
          'Retry failed — check the printer (${e.message})',
          type: UiSnackBarType.error,
          label: 'Retry',
          onLabelPressed: () => _retryPrint(report),
        );
      }
    }
  }

  /// Almost irreversible — the cashout row is the final record of the shift —
  /// so it gets an explicit confirmation before anything else happens.
  Future<bool> _confirmClose(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded),
            SizedBox(width: Space.md),
            UiText('Cash out and print report?', type: UiTextType.titleMedium),
          ],
        ),
        content: const UiText(
          'This will close your shift, print the final sales report and log '
          'you out. You will need to sign in again to take orders.',
          type: UiTextType.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cash out'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Asks for the physical cash counted in the drawer ("DH 0.00" decimal
  /// input, prefilled with the expected total so the waiter only corrects it).
  /// Returns cents, or `null` when cancelled.
  Future<int?> _askCashCounted(
    BuildContext context, {
    required int expectedCents,
  }) {
    final controller = TextEditingController(text: _centsToDh(expectedCents));
    final formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payments_rounded),
            SizedBox(width: Space.md),
            UiText('Cash counted', type: UiTextType.titleMedium),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Cash in the drawer',
                  prefixText: 'DH ',
                  helperText: 'The sum of cash you can hand over at the end.',
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(dialogContext).pop(_dhToCents(controller.text));
                  }
                },
              ),
              SizedBox(height: Space.md),
              UiText(
                'Expected: ${_centsToDh(expectedCents)} — variance is computed '
                'against this amount.',
                type: UiTextType.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          UiButton(
            'Confirm cash out',
            variant: UiButtonVariant.filled,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(_dhToCents(controller.text));
              }
            },
          ),
        ],
      ),
    );
  }

  static int _dhToCents(String value) =>
      (double.parse(value.trim()) * 100).round();

  static String _centsToDh(int cents) =>
      (cents / 100).toStringAsFixed(2);
}
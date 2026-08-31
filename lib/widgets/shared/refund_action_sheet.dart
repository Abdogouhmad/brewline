import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/printing/receipt_printer_service.dart';
import 'package:brewline/core/printing/receipt_templates/refund_receipt_template.dart';
import 'package:brewline/core/repositories/refund_repository.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'order_refund_form.dart';

/// The responsive refund entry point: opens the shared [OrderRefundForm] as a
/// **fixed-width dialog on desktop** (`ScreenSize.expanded`) or a **full-width
/// rounded bottom sheet on compact/medium** (mobile & tablet), chosen live by
/// [Breakpoints.of] — i.e. by the current screen *width*, not device type.
///
/// This desktop-dialog / mobile-bottom-sheet split is deliberate responsive
/// behaviour, not two divergent implementations: both shells render the exact
/// same form content. After a successful refund the shell switches to a brief
/// confirmation with an optional "Print refund receipt" action (§6 — printing
/// is never automatic; the admin decides whether a paper copy is needed).
Future<void> showRefundActionSheet(
  BuildContext context, {
  required int orderId,
}) {
  final screen = Breakpoints.of(context);
  final Widget flow = _RefundFlow(orderId: orderId);

  if (screen == ScreenSize.expanded) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Space.x2l,
          vertical: Space.x2l,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rounded.x2l),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(child: flow),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Rounded.x2l)),
    ),
    builder: (_) => FractionallySizedBox(heightFactor: 0.92, child: flow),
  );
}

/// Owns the refund state machine inside whichever shell hosts it: resolve the
/// current admin, show the form, then (on success) the confirmation + optional
/// print. Lives inside the sheet/dialog so `Navigator.pop` closes the shell.
class _RefundFlow extends ConsumerStatefulWidget {
  final int orderId;

  const _RefundFlow({required this.orderId});

  @override
  ConsumerState<_RefundFlow> createState() => _RefundFlowState();
}

class _RefundFlowState extends ConsumerState<_RefundFlow> {
  RefundResult? _done;

  Future<void> _onFormResult(RefundResult result) async {
    setState(() => _done = result);
  }

  Future<void> _print(ReceiptPrinterService printer) async {
    final result = _done!;
    try {
      final repo = await ref.read(refundRepositoryProvider.future);
      final order = await repo.getOrder(widget.orderId);
      if (!mounted) return;
      final adminId = ref.read(authProvider).value?.userId ?? 'admin';

      await printer.printRefundReceipt(
        RefundReceiptData(
          originalTotalCents: ((order?.total ?? 0) * 100).round(),
          refundedCents: result.amountCents,
          reason: '',
          adminName: adminId,
          orderNumber: order?.orderNumber ?? 0,
          orderId: widget.orderId,
          at: result.at,
        ),
      );
      if (mounted) {
        showUiSnackBar(
          context,
          'Refund receipt sent to printer',
          type: UiSnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showUiSnackBar(
          context,
          'Print failed: ${e.toString()}',
          type: UiSnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final adminId = state.value?.userId;

    if (_done != null) {
      return _RefundSuccessView(
        result: _done!,
        orderId: widget.orderId,
        onPrint: (p) => _print(p),
      );
    }

    if (adminId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: Space.x3l),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return OrderRefundForm(
      orderId: widget.orderId,
      adminId: adminId,
      onDone: _onFormResult,
    );
  }
}

/// Brief confirmation shown after a refund, with the optional print action.
class _RefundSuccessView extends ConsumerWidget {
  final RefundResult result;
  final int orderId;
  final Future<void> Function(ReceiptPrinterService) onPrint;

  const _RefundSuccessView({
    required this.result,
    required this.orderId,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final printer = ref.watch(receiptPrinterServiceProvider);

    return Padding(
      padding: EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_rounded,
              color: colorScheme.primary, size: 48),
          SizedBox(height: Space.lg),
          UiText(
            result.isFull ? 'Order voided' : 'Refund successful',
            type: UiTextType.titleLarge,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Space.md),
          UiText(
            '${result.isFull ? 'Voided and refunded' : 'Refunded'} '
            '${formatPrice(result.amountCents / 100)} on order #$orderId.',
            type: UiTextType.bodyMedium,
            textAlign: TextAlign.center,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: Space.xl),
          UiButton(
            'Print refund receipt',
            icon: Icons.print_rounded,
            variant: UiButtonVariant.tonal,
            expand: true,
            onPressed: () => onPrint(printer),
          ),
          SizedBox(height: Space.md),
          UiButton(
            'Done',
            variant: UiButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

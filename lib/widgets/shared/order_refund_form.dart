import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/order_item_adjustment.dart';
import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/repositories/order_journal_repository.dart';
import 'package:brewline/core/repositories/refund_repository.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/widgets/shared/app_text_field.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_card.dart';
import 'package:brewline/shared/ui/ui_modal.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// The shared refund form — used identically inside a desktop [Dialog] or a
/// mobile [showModalBottomSheet], whichever [RefundActionSheet] picks.
///
/// Contains the whole §5 form: a read-only order summary, a "Correct Order /
/// Void Order" toggle, (in correct mode) quantity steppers that can only go
/// down plus per-line remove actions, a required reason field, and a confirm
/// button whose label includes the refunded amount. On success it pops itself
/// and reports [RefundResult] so the shell can show the success state with an
/// optional print action (§6).
class OrderRefundForm extends ConsumerStatefulWidget {
  final int orderId;
  final String adminId;

  /// Called with the result after a successful refund; the owning shell
  /// switches to its success/print state. When null, the form pops itself
  /// instead (standalone usage).
  final ValueChanged<RefundResult>? onDone;

  const OrderRefundForm({
    super.key,
    required this.orderId,
    required this.adminId,
    this.onDone,
  });

  @override
  ConsumerState<OrderRefundForm> createState() => _OrderRefundFormState();
}

enum _RefundMode { correct, voidOrder }

class _OrderRefundFormState extends ConsumerState<OrderRefundForm> {
  _RefundMode _mode = _RefundMode.correct;

  /// Original line quantities at load — used to bound the steppers so a
  /// correction can never raise a total (decrease-only, §2.1).
  Map<int, int> _originalQty = {};
  late final Map<int, int> _qty = {};

  OrderRecord? _order;
  Object? _loadError;
  bool _busy = false;

  /// Reason text, validated non-empty.
  String _reason = '';

  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      if (_reason != _reasonController.text && mounted) {
        setState(() => _reason = _reasonController.text);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loadError = null;
      _order = null;
    });
    try {
      final repo = await ref.read(refundRepositoryProvider.future);
      final order = await repo.getOrder(widget.orderId);
      if (!mounted) return;
      if (order == null) {
        setState(() => _loadError = 'Order not found');
        return;
      }
      final original = {
        for (final item in order.items) item.id: item.quantity,
      };
      setState(() {
        _order = order;
        _originalQty = original;
        _qty..clear()..addAll(original);
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  /// True when the order has already been voided (nothing left to refund).
  bool get _alreadyVoided => _order?.isVoided ?? false;

  /// Sum of the current (edited) line totals.
  double get _currentTotal =>
      _order?.items.fold<double>(0, (sum, i) => sum + (_qty[i.id] ?? 0) * i.unitPrice) ??
      0;

  /// Refund amount in correct mode: original total minus current total.
  double get _correctRefund =>
      ((_order?.total ?? 0) - _currentTotal).clamp(0, double.maxFinite);

  /// Whether at least one line has actually been reduced in correct mode.
  bool get _hasChanges =>
      _order?.items.any((i) => (_qty[i.id] ?? 0) < (_originalQty[i.id] ?? 0)) ??
      false;

  /// Target refund amount for the confirm label.
  double get _refundAmount => _mode == _RefundMode.voidOrder
      ? _order?.total ?? 0
      : _correctRefund;

  /// Confirm is enabled only when there's a non-empty reason and, in correct
  /// mode, at least one real reduction has been made.
  bool get _canConfirm =>
      !_busy &&
      !_alreadyVoided &&
      _reason.trim().isNotEmpty &&
      (_mode == _RefundMode.voidOrder || _hasChanges) &&
      _refundAmount > 0;

  Future<void> _submit() async {
    if (!_canConfirm) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(refundRepositoryProvider.future);
      final RefundResult result;
      if (_mode == _RefundMode.voidOrder) {
        result = await repo.voidOrder(
          orderId: widget.orderId,
          reason: _reason.trim(),
          adminId: widget.adminId,
        );
      } else {
        final adjustments = <OrderItemAdjustment>[
          for (final item in _order!.items)
            if ((_qty[item.id] ?? 0) < (_originalQty[item.id] ?? 0))
              OrderItemAdjustment(
                orderItemId: item.id,
                originalQuantity: _originalQty[item.id]!,
                unitPrice: item.unitPrice,
                newQuantity: _qty[item.id]!,
              ),
        ];
        result = await repo.applyPartialRefund(
          orderId: widget.orderId,
          adjustments: adjustments,
          reason: _reason.trim(),
          adminId: widget.adminId,
        );
      }
      if (!mounted) return;
      ref.read(journalMutationProvider.notifier).bump();
      final onDone = widget.onDone;
      if (onDone != null) {
        onDone(result);
      } else {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showUiSnackBar(
        context,
        'Refund failed: ${e.toString()}',
        type: UiSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: adaptiveModalPadding(context),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loadError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiText('Couldn\'t load this order.', type: UiTextType.titleMedium),
          SizedBox(height: Space.md),
          UiButton('Retry', onPressed: () => _load()),
        ],
      );
    }
    if (_order == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Space.x3l),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final order = _order!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(colorScheme),
        SizedBox(height: Space.lg),
        _OrderSummary(order: order),
        SizedBox(height: Space.lg),
        _modeToggle(colorScheme),
        SizedBox(height: Space.lg),
        if (_mode == _RefundMode.correct)
          _lineEditor(colorScheme, order)
        else
          _voidSummary(colorScheme, order),
        SizedBox(height: Space.xl),
        AppTextField(
          label: 'Reason (required)',
          controller: _reasonController,
          hintText: 'e.g. wrong item entered',
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: Space.xl),
        _confirmButton(),
      ],
    );
  }

  Widget _header(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.receipt_long_rounded, color: colorScheme.primary),
        SizedBox(width: Space.md),
        UiText(
          'Refund order',
          type: UiTextType.titleLarge,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }

  Widget _modeToggle(ColorScheme colorScheme) {
    return SegmentedButton<_RefundMode>(
      segments: const [
        ButtonSegment(
          value: _RefundMode.correct,
          label: Text('Correct Order'),
          icon: Icon(Icons.edit_rounded),
        ),
        ButtonSegment(
          value: _RefundMode.voidOrder,
          label: Text('Void Order'),
          icon: Icon(Icons.delete_outline_rounded),
        ),
      ],
      selected: {_mode},
      onSelectionChanged: (set) =>
          setState(() => _mode = set.first),
    );
  }

  Widget _lineEditor(ColorScheme colorScheme, OrderRecord order) {
    return UiCard(
      title: 'Line items',
      compact: true,
      content: Column(
        children: [
          for (final item in order.items)
            _LineRow(
              item: item,
              quantity: _qty[item.id] ?? item.quantity,
              maxQuantity: _originalQty[item.id] ?? item.quantity,
              onDecrement: _qty[item.id]! > 0
                  ? () => setState(() => _qty[item.id] = _qty[item.id]! - 1)
                  : null,
              onRemove: _qty[item.id]! > 0
                  ? () => setState(() => _qty[item.id] = 0)
                  : null,
            ),
          SizedBox(height: Space.md),
          _totalRow(
            'Current total',
            _currentTotal,
            isCurrent: true,
            colorScheme: colorScheme,
          ),
          if (_hasChanges) ...[
            SizedBox(height: Space.xs),
            _totalRow(
              'Refund amount',
              _correctRefund,
              isRefund: true,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _voidSummary(ColorScheme colorScheme, OrderRecord order) {
    return UiCard(
      title: 'Void entire order',
      compact: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _totalRow(
            'Original total',
            order.total,
            isCurrent: true,
            colorScheme: colorScheme,
          ),
          SizedBox(height: Space.xs),
          _totalRow(
            'Refund amount',
            order.total,
            isRefund: true,
            colorScheme: colorScheme,
          ),
          SizedBox(height: Space.md),
          UiText(
            'The order is marked voided but kept in records for audit. '
            'Nothing is deleted.',
            type: UiTextType.bodySmall,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    double amount, {
    ColorScheme? colorScheme,
    bool isCurrent = false,
    bool isRefund = false,
  }) {
    final scheme = colorScheme ?? Theme.of(context).colorScheme;
    final color = isRefund ? scheme.error : scheme.onSurface;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UiText(label, type: UiTextType.bodyMedium),
          UiText(
            formatPrice(amount),
            type: UiTextType.bodyMedium,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _confirmButton() {
    final refund = _refundAmount;
    final label = _mode == _RefundMode.voidOrder
        ? 'Void & refund ${formatPrice(refund)}'
        : 'Refund ${formatPrice(refund)}';
    return UiButton(
      _busy ? 'Processing…' : label,
      icon: _mode == _RefundMode.voidOrder
          ? Icons.delete_outline_rounded
          : Icons.currency_exchange_rounded,
      variant: _mode == _RefundMode.voidOrder
          ? UiButtonVariant.filled
          : UiButtonVariant.filled,
      expand: true,
      onPressed: _canConfirm ? _submit : null,
    );
  }
}

/// Read-only summary of the order being refunded.
class _OrderSummary extends StatelessWidget {
  final OrderRecord order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orderNumber = order.orderNumber > 0
        ? '#${order.orderNumber.toString().padLeft(3, '0')}'
        : '#${order.id}';

    return UiCard(
      title: 'Order $orderNumber',
      subtitle: '${order.waiterUsername ?? '—'} · ${_dateTime(order.createdAt)}',
      compact: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in order.items)
            Padding(
              padding: EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: UiText(
                      '${item.quantity} × ${item.name}',
                      type: UiTextType.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  UiText(
                    formatPrice(item.quantity * item.unitPrice),
                    type: UiTextType.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          Divider(height: Space.md, color: colorScheme.outlineVariant),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UiText(
                'Total',
                type: UiTextType.bodyMedium,
                fontWeight: FontWeight.w700,
              ),
              UiText(
                formatPrice(order.total),
                type: UiTextType.bodyMedium,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// One editable line: name, price, a quantity stepper (down only) and a
/// remove (×) action.
class _LineRow extends StatelessWidget {
  final OrderLineItem item;
  final int quantity;
  final int maxQuantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;

  const _LineRow({
    required this.item,
    required this.quantity,
    required this.maxQuantity,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final atMax = quantity >= maxQuantity;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(item.name, type: UiTextType.bodyMedium),
                UiText(
                  formatPrice(item.unitPrice),
                  type: UiTextType.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove item',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: quantity == 0 ? null : onRemove,
          ),
          IconButton(
            tooltip: 'Reduce quantity',
            icon: Icon(
              Icons.remove_circle_outline_rounded,
              color: atMax || quantity == 0
                  ? colorScheme.outlineVariant
                  : colorScheme.error,
            ),
            onPressed: quantity == 0 || onDecrement == null ? null : onDecrement,
          ),
          SizedBox(
            width: 40,
            child: UiText(
              '$quantity',
              type: UiTextType.titleMedium,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

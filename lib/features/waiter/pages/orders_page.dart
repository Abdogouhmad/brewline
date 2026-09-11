import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/waiter/providers/order_provider.dart';
import 'package:brewline/core/utils/price_format.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_list.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Orders tab content / left pane on desktop.
/// Title lives in the [AppShell] app bar — no local one.
///
/// Fully driven by [orderControllerProvider]: tap menu cards to fill it,
/// remove lines here, then charge or clear.
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final orderItems = ref.watch(orderControllerProvider);
    final total = ref.watch(orderTotalProvider);
    final order = ref.read(orderControllerProvider.notifier);

    /// Charges the order — persists it to the journal, advances the ticket
    /// number and resets the cart. TODO: real payment flow.
    Future<void> charge() async {
      await order.charge();
      if (!context.mounted) return;
    }

    /// Empties the order without charging. Keeps a backup so the snackbar's
    /// Undo can restore the cart if the tap was accidental.
    void clear() {
      final backup = [...ref.read(orderControllerProvider)];
      order.clear();
      showUiSnackBar(
        context,
        l10n.ordersCleared,
        icon: Icons.delete_sweep_outlined,
        duration: const Duration(seconds: 4),
        label: l10n.ordersUndo,
        onLabelPressed: () => order.restore(backup),
      );
    }

    // Localized ticket header — the provider stays code-based (§4), display
    // copy is resolved here per locale.
    final units = totalUnitsOf(orderItems);
    final title = units > 1
        ? l10n.ordersTitleWithItems(ref.watch(orderNumberProvider), units)
        : l10n.ordersTitle(ref.watch(orderNumberProvider));

    return Column(
      children: [
        Expanded(
          child: orderItems.isEmpty
              ? const _EmptyOrderView()
              : ListView(
                  padding: EdgeInsets.all(Space.lg),
                  children: [
                    UiListSection(
                      title: title,
                      children: [
                        UiListGroup(
                          useCard: false,
                          children: [
                            for (final item in orderItems)
                              UiListTile(
                                title: item.quantity > 1
                                    ? '${item.product.name} ×${item.quantity}'
                                    : item.product.name,
                                price: item.formattedTotal,
                                actionIcon: Icons.delete_outline_rounded,
                                actionTooltip: l10n.ordersRemoveItem,
                                onActionPressed: () =>
                                    order.remove(item.product.id),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        ),

        // Summary + actions pinned to the bottom.
        const Divider(height: 1, thickness: 0.5),
        Padding(
          padding: EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  UiText(
                    l10n.ordersTotal,
                    type: UiTextType.titleMedium,
                    fontWeight: FontWeight.w700,
                  ),
                  UiText(
                    formatPriceCents(total),
                    type: UiTextType.titleMedium,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ],
              ),
              SizedBox(height: Space.xl),
              UiButton(
                l10n.ordersCharge(formatPriceCents(total)),
                expand: true,
                onPressed: total <= 0 ? null : charge,
              ),
              SizedBox(height: Space.md),
              UiButton(
                l10n.ordersClearOrder,
                variant: UiButtonVariant.outlined,
                expand: true,
                onPressed: orderItems.isEmpty ? null : clear,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown while the cart is empty — guides waiters to the Menu tab.
class _EmptyOrderView extends StatelessWidget {
  const _EmptyOrderView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: Space.md),
          UiText(
            l10n.ordersEmpty,
            type: UiTextType.titleMedium,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: Space.sm),
          UiText(
            l10n.ordersEmptyHint,
            type: UiTextType.bodySmall,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

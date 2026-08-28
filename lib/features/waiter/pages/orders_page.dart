import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/waiter/providers/order_provider.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
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
    final orderItems = ref.watch(orderControllerProvider);
    final total = ref.watch(orderTotalProvider);
    final order = ref.read(orderControllerProvider.notifier);

    /// Charges the order — advances the ticket number, logs the receipt
    /// to the terminal and resets the cart. TODO: real payment flow.
    void charge() {
      final charged = ref.read(orderTotalProvider);
      ref.read(orderNumberProvider.notifier).advance();
      order.charge();
      showUiSnackBar(
        context,
        'Charged ${formatPrice(charged)}',
        type: UiSnackBarType.success,
      );
    }

    /// Empties the order without charging.
    void clear() {
      order.clear();
      showUiSnackBar(
        context,
        'Order cleared',
        icon: Icons.delete_sweep_outlined,
        duration: const Duration(seconds: 2),
      );
    }

    return Column(
      children: [
        Expanded(
          child: orderItems.isEmpty
              ? const _EmptyOrderView()
              : ListView(
                  padding: EdgeInsets.all(Space.lg),
                  children: [
                    UiListSection(
                      title: ref.watch(orderTitleProvider),
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
                                actionTooltip: 'Remove item',
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
                  const UiText(
                    'Total',
                    type: UiTextType.titleMedium,
                    fontWeight: FontWeight.w700,
                  ),
                  UiText(
                    formatPrice(total),
                    type: UiTextType.titleMedium,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ],
              ),
              SizedBox(height: Space.xl),
              UiButton(
                'Charge ${formatPrice(total)}',
                expand: true,
                onPressed: total <= 0 ? null : charge,
              ),
              SizedBox(height: Space.md),
              UiButton(
                'Clear order',
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
            'No items yet',
            type: UiTextType.titleMedium,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: Space.sm),
          UiText(
            'Tap products in Menu to add them here.',
            type: UiTextType.bodySmall,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

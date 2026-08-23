import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_list.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Orders tab content / left pane on desktop.
/// Title lives in the [AppShell] app bar — no local one.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(Space.lg),
            children: [
              UiListSection(
                title: 'Order #12',
                children: [
                  UiListGroup(
                    useCard: false,
                    children: [
                      UiListTile(
                        title: 'Flat White',
                        subtitle: 'Double shot · whole milk',
                        price: '\$4.50',
                        actionIcon: Icons.delete_outline_rounded,
                        actionTooltip: 'Remove item',
                      ),
                      UiListTile(
                        title: 'Croissant',
                        subtitle: 'Butter, baked fresh',
                        price: '\$3.20',
                        actionIcon: Icons.delete_outline_rounded,
                        actionTooltip: 'Remove item',
                      ),
                      UiListTile(
                        title: 'Iced Latte',
                        subtitle: 'Oat milk · extra ice',
                        price: '\$5.00',
                        actionIcon: Icons.delete_outline_rounded,
                        actionTooltip: 'Remove item',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Summary + actions pinned to the bottom.
        Divider(height: 1, thickness: 0.5),
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
                    '\$12.70',
                    type: UiTextType.titleMedium,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ],
              ),
              SizedBox(height: Space.xl),
              UiButton(
                'Charge \$12.70',
                expand: true,
                onPressed: () => showUiSnackBar(
                  context,
                  'Charged \$12.70',
                  type: UiSnackBarType.success,
                ),
              ),
              SizedBox(height: Space.md),
              UiButton(
                'Clear order',
                variant: UiButtonVariant.outlined,
                expand: true,
                onPressed: () => showUiSnackBar(
                  context,
                  'Order #12 cleared',
                  icon: Icons.delete_sweep_outlined,
                  duration: const Duration(seconds: 2),
                  label: 'Undo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

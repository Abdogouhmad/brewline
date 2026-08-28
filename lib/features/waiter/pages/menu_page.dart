import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/features/waiter/providers/order_provider.dart';
import 'package:brewline/features/waiter/providers/product_provider.dart';
import 'package:brewline/shared/ui/ui_card.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Menu tab content for the waiter profile.
///
/// Renders [productsProvider] (dummy catalog for now — bind to the real
/// product table when available) as a responsive grid of [UiCard]s.
/// Tapping a card adds the product to the current order.
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: Space.sm, bottom: Space.md),
            child: UiText(
              'MENU',
              type: UiTextType.labelLarge,
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          ResponsiveGrid(
            // Compact subtitle-less menu cards: 2 / 3 / 5 columns.
            mobileColumns: 2,
            tabletColumns: 3,
            desktopColumns: 5,
            crossAxisSpacing: Space.md,
            mainAxisSpacing: Space.md,
            childAspectRatio: 0.9,
            padding: EdgeInsets.zero,
            children: [
              // Tapping a card adds the product to the open order.
              for (final product in products)
                UiCard(
                  compact: true,
                  image: Image.asset(product.imagePath, fit: BoxFit.cover),
                  title: product.name,
                  actions: [
                    UiText(product.formattedPrice, fontWeight: FontWeight.w700),
                  ],
                  onTap: () =>
                      ref.read(orderControllerProvider.notifier).add(product),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/features/waiter/providers/order_provider.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_card.dart';
import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/shared/widgets/product_image.dart';

/// Menu tab content for the waiter profile.
///
/// Renders the available products from the shared catalog
/// ([menuProductsProvider]) as a responsive grid of [UiCard]s. Tapping a card
/// adds the product to the current order. Updates live when the admin edits
/// the catalog.
///
/// Stock levels are intentionally **not** shown here — stock is admin-only
/// information (private to the admin stock page), so waiters just see the menu
/// and price, never low/out alerts.
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(menuProductsProvider);
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
          products.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Space.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: EdgeInsets.all(Space.xl),
              child: UiText(
                'Couldn\'t load the menu.',
                type: UiTextType.bodyMedium,
                color: colorScheme.error,
              ),
            ),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(Space.xl),
                    child: UiText(
                      'No products on the menu yet.',
                      type: UiTextType.bodyMedium,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : ResponsiveGrid(
                    mobileColumns: 2,
                    tabletColumns: 3,
                    desktopColumns: 5,
                    crossAxisSpacing: Space.md,
                    mainAxisSpacing: Space.md,
                    childAspectRatio: 0.9,
                    padding: EdgeInsets.zero,
                    children: [
                      for (final product in items)
                        UiCard(
                          compact: true,
                          image: ProductImage(path: product.imagePath),
                          title: product.name,
                          actions: [
                            UiText(
                              formatPrice(product.price),
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                          onTap: () => ref
                              .read(orderControllerProvider.notifier)
                              .add(product),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/features/admin/widgets/availability_toggle.dart';
import 'package:brewline/features/admin/widgets/product_form_sheet.dart';
import 'package:brewline/features/waiter/providers/price_format.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/shared/widgets/product_image.dart';

/// Responsive catalog: a single-column card list on phones, a two-up grid on
/// tablets and a wider grid on desktop, driven by [allProductsProvider].
class ProductTable extends ConsumerWidget {
  const ProductTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(allProductsProvider);

    return products.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Space.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Center(
        child: UiText(
          'Couldn\'t load the catalog.',
          type: UiTextType.bodyMedium,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(Space.x2l),
              child: UiText(
                'No products yet — add your first one.',
                type: UiTextType.bodyMedium,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);
            final columnWidth = (width - Space.lg * (columns - 1)) / columns;
            return Wrap(
              spacing: Space.lg,
              runSpacing: Space.lg,
              children: [
                for (final product in items)
                  SizedBox(
                    width: columnWidth,
                    child: _ProductCard(product: product),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.x2l),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(imagePath: product.imagePath),
          Padding(
            padding: EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: UiText(
                        product.name,
                        type: UiTextType.titleMedium,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _ProductMenu(product: product),
                  ],
                ),
                SizedBox(height: Space.xs),
                Row(
                  children: [
                    UiText(
                      product.category.isEmpty
                          ? 'Uncategorised'
                          : product.category,
                      type: UiTextType.labelSmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: Space.md),
                    UiText(
                      formatPrice(product.price),
                      type: UiTextType.titleSmall,
                      fontWeight: FontWeight.w800,
                    ),
                  ],
                ),
                SizedBox(height: Space.md),
                _StockLine(product: product),
                SizedBox(height: Space.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: AvailabilityToggle(
                    productId: product.id,
                    available: product.available,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String imagePath;

  const _Thumb({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      // Shared loader handles asset paths, stable file paths and the generic
      // cup placeholder (never a broken-image icon).
      child: ProductImage(path: imagePath, iconSize: 40),
    );
  }
}

class _StockLine extends StatelessWidget {
  final Product product;

  const _StockLine({required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (Color color, String text) = !product.available
        ? (colorScheme.outline, 'Sold out')
        : product.stockQuantity <= 0
        ? (colorScheme.onSurfaceVariant, 'Stock not tracked')
        : product.isLowStock
        ? (
            colorScheme.error,
            '${product.stockQuantity} left'
                ' (alerts below ${product.lowStockThreshold})',
          )
        : (colorScheme.tertiary, '${product.stockQuantity} in stock');

    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: AppSizes.iconSm, color: color),
        SizedBox(width: Space.sm),
        UiText(text, type: UiTextType.bodySmall, color: color),
      ],
    );
  }
}

class _ProductMenu extends ConsumerWidget {
  final Product product;

  const _ProductMenu({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Product actions',
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await showProductFormSheet(context, product: product);
          case 'delete':
            if (await _confirmDelete(context, product)) {
              await ref
                  .read(productMutationProvider.notifier)
                  .delete(product.id);
            }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: UiText('Delete ${product.name}?', type: UiTextType.titleMedium),
        content: UiText(
          'Removes it from the menu and stock tracking. Past orders keep '
          'their own snapshots and stay in the reports.',
          type: UiTextType.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      if (context.mounted) {
        showUiSnackBar(
          context,
          '${product.name} deleted',
          type: UiSnackBarType.warning,
        );
      }
    }
    return confirmed ?? false;
  }
}

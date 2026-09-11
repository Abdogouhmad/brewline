import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/features/admin/widgets/availability_toggle.dart';
import 'package:brewline/features/admin/widgets/product_form_sheet.dart';
import 'package:brewline/core/utils/price_format.dart';
import 'package:brewline/features/waiter/providers/stock_status_provider.dart';
import 'package:brewline/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return products.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(Space.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Center(
        child: UiText(
          l10n.productTableError,
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
                l10n.productTableEmpty,
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
    final l10n = AppLocalizations.of(context)!;

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
                          ? l10n.productUncategorised
                          : product.category,
                      type: UiTextType.labelSmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: Space.md),
                    UiText(
                      formatPriceCents(product.priceCents),
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

/// Stock status per product, derived from the ingredient binding + the live
/// ingredient stock (the same source as the waiter badges, stock.md §3.2) —
/// NOT the legacy per-product `stock_quantity`, which is no longer entered in
/// the product form.
class _StockLine extends ConsumerWidget {
  final Product product;

  const _StockLine({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final stock = ref.watch(productStockProvider).value;
    final info = stock?[product.id];

    final (Color color, String text) =
        !product.available
            ? (colorScheme.outline, l10n.productStockSoldOut)
        : info == null
            ? (colorScheme.onSurfaceVariant, l10n.productStockNotTracked)
        : info.status == ProductStockStatus.out
            ? (colorScheme.error, l10n.productStockOutRestock)
        : info.status == ProductStockStatus.low
            ? (colorScheme.error, l10n.productStockLow(info.servingsLeft))
        : info.servingsLeft <= 0
            ? (colorScheme.error, l10n.productStockOutRestock)
            : (colorScheme.tertiary, l10n.productStockServingsLeft(info.servingsLeft));

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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: l10n.productActionsTooltip,
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
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
        PopupMenuItem(
          value: 'delete',
          child: Text(l10n.actionDelete, style: TextStyle(color: colorScheme.error)),
        ),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: UiText(l10n.productDeleteTitle(product.name), type: UiTextType.titleMedium),
        content: UiText(
          l10n.productDeleteBody,
          type: UiTextType.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      if (context.mounted) {
        showUiSnackBar(
          context,
          l10n.productDeletedSnackbar(product.name),
          type: UiSnackBarType.warning,
        );
      }
    }
    return confirmed ?? false;
  }
}

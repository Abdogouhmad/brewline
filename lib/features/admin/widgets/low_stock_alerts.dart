import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/features/admin/widgets/dashboard_card.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Products running low on stock with one-tap restock (+10 units).
///
/// Writes go through [productMutationProvider] so the catalog, the shop and
/// this card all refresh from the same write.
class LowStockAlerts extends ConsumerWidget {
  const LowStockAlerts({super.key});

  static const int _restockIncrement = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(lowStockProductsProvider);

    return DashboardCard(
      title: 'Low stock',
      icon: Icons.inventory_2_outlined,
      child: products.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(Space.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _message(context, 'Couldn\'t load stock levels.'),
        data: (items) {
          if (items.isEmpty) {
            return _message(context, 'Stock levels look healthy — no alerts.');
          }
          return Column(
            children: [
              for (final product in items)
                _LowStockTile(
                  product: product,
                  onRestock: () => _restock(ref, product),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _restock(WidgetRef ref, Product product) async {
    await ref
        .read(productMutationProvider.notifier)
        .restock(product.id, _restockIncrement);
  }

  Widget _message(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Space.xl),
      child: Center(
        child: UiText(
          text,
          type: UiTextType.bodyMedium,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final Product product;
  final VoidCallback onRestock;

  const _LowStockTile({required this.product, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final critical = product.stockQuantity == 0;

    return Padding(
      padding: EdgeInsets.only(bottom: Space.md),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Space.xs),
            decoration: BoxDecoration(
              color: critical
                  ? colorScheme.errorContainer
                  : colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(Rounded.md),
            ),
            child: Icon(
              critical
                  ? Icons.priority_high_rounded
                  : Icons.warning_amber_rounded,
              size: AppSizes.iconSm,
              color: critical
                  ? colorScheme.onErrorContainer
                  : colorScheme.onTertiaryContainer,
            ),
          ),
          SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(
                  product.name,
                  type: UiTextType.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
                UiText(
                  '${product.stockQuantity} left',
                  type: UiTextType.bodySmall,
                  color: critical
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          SizedBox(width: Space.sm),
          TextButton(
            onPressed: onRestock,
            child: UiText(
              '+ Restock',
              type: UiTextType.labelLarge,
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

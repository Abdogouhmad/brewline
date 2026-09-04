import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/ingredient_format.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/features/admin/providers/ingredient_servings_provider.dart';
import 'package:brewline/features/admin/widgets/dashboard_card.dart';
import 'package:brewline/features/admin/widgets/restock_dialog.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// At-a-glance overview of **every** non-archived ingredient's on-hand stock,
/// sorted so items needing attention surface first (out → low → healthy).
///
/// Unlike a low-stock-only alert, this lists all stock so the admin can see the
/// whole picture from the dashboard without opening the Inventory page. Each
/// row shows the quantity left, an estimate of servings remaining (when the
/// ingredient feeds a product), and a one-tap Restock action. Live: refreshed
/// on every stock write via [ingredientMutationProvider].
class StockOverviewCard extends ConsumerWidget {
  const StockOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredients = ref.watch(allIngredientsProvider);
    final servingsByIngredient =
        ref.watch(ingredientServingsProvider).value ?? const {};

    return DashboardCard(
      title: 'Stock overview',
      icon: Icons.inventory_2_outlined,
      trailing: switch (ingredients) {
        AsyncData(:final value) when value.isNotEmpty =>
          _StatusPill(issues: value.where((i) => i.isLowStock).length),
        _ => null,
      },
      child: ingredients.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(Space.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => _message(context, 'Couldn\'t load stock levels.'),
        data: (items) {
          if (items.isEmpty) {
            return _message(
              context,
              'No stock items yet — add ingredients to track stock here.',
            );
          }

          final sorted = [...items]..sort(_byAlertPriority);
          // Keep the card a "glance", not a full page: cap its height and let
          // the rest scroll when there are many ingredients.
          final maxHeight = Breakpoints.of(context) == ScreenSize.compact
              ? 260.0
              : 360.0;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final ingredient in sorted)
                    _StockTile(
                      ingredient: ingredient,
                      servingsLeft: servingsByIngredient[ingredient.id],
                      onRestock: () => showRestockDialog(
                        context,
                        ingredient: ingredient,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

/// Out first, then low, then healthy; within a group the emptiest first.
int _byAlertPriority(Ingredient a, Ingredient b) {
  final (ra, rb) = (a.isOutOfStock ? 0 : a.isLowStock ? 1 : 2,
      b.isOutOfStock ? 0 : b.isLowStock ? 1 : 2);
  final byPriority = ra.compareTo(rb);
  if (byPriority != 0) return byPriority;
  return a.currentStock.compareTo(b.currentStock);
}

/// "N need restock" pill in the card header (hidden when all healthy).
class _StatusPill extends StatelessWidget {
  final int issues;

  const _StatusPill({required this.issues});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: UiText(
        '$issues need restock',
        type: UiTextType.labelSmall,
        fontWeight: FontWeight.w700,
        color: colorScheme.onTertiaryContainer,
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final Ingredient ingredient;
  final int? servingsLeft;
  final VoidCallback onRestock;

  const _StockTile({
    required this.ingredient,
    required this.servingsLeft,
    required this.onRestock,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final out = ingredient.isOutOfStock;
    final low = ingredient.isLowStock;

    final (background, foreground, icon) = out
        ? (colorScheme.errorContainer, colorScheme.onErrorContainer,
            Icons.priority_high_rounded)
        : low
            ? (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer,
                Icons.warning_amber_rounded)
            : (colorScheme.surfaceContainerHighest,
                colorScheme.onSurfaceVariant, Icons.check_circle_outline);

    final quantity =
        '${formatStockQuantity(ingredient.currentStock, ingredient.unit)} left';
    final servingsNote = servingsLeft != null
        ? ' · ~$servingsLeft serving${servingsLeft == 1 ? '' : 's'}'
        : '';
    final statusNote = out
        ? ' · out'
        : low
            ? ' · low'
            : '';
    final bodyColor = out
        ? colorScheme.error
        : low
            ? colorScheme.tertiary
            : colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.only(bottom: Space.md),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Space.xs),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(Rounded.md),
            ),
            child: Icon(
              icon,
              size: AppSizes.iconSm,
              color: foreground,
            ),
          ),
          SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(
                  ingredient.name,
                  type: UiTextType.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
                UiText(
                  '$quantity$servingsNote$statusNote',
                  type: UiTextType.bodySmall,
                  color: bodyColor,
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
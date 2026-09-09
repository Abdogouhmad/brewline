import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/repositories/ingredient_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/features/admin/pages/stock_movements_page.dart';
import 'package:brewline/features/admin/widgets/ingredient_form_sheet.dart';
import 'package:brewline/features/admin/widgets/ingredient_tile.dart';
import 'package:brewline/features/admin/widgets/inventory_expandable_fab.dart';
import 'package:brewline/features/admin/widgets/restock_dialog.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Admin "Inventory" tab: the ingredient catalog with live quantities.
///
/// Quantities only ever change through [StockMovementRepository] (the single
/// writer) via the restock dialog; editing/archiving here touches name
/// /threshold/availability, never `current_stock` directly (stock.md §2).
/// A low/out-of-stock badge mirrors what the dashboard card and the
/// Inventory nav badge show.
class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final ingredients = ref.watch(allIngredientsProvider);
    final compact = Breakpoints.of(context) == ScreenSize.compact;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? Space.lg : Space.full,
          vertical: Space.lg,
        ),
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(
                  'Track raw ingredients and who consumes them.',
                  type: UiTextType.bodyMedium,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiText(
                        'Inventory',
                        type: UiTextType.headlineSmall,
                        fontWeight: FontWeight.w800,
                      ),
                      SizedBox(height: Space.xs),
                      UiText(
                        'Track raw ingredients and who consumes them.',
                        type: UiTextType.bodyMedium,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                UiButton(
                  'Add ingredient',
                  icon: Icons.add_box_rounded,
                  variant: UiButtonVariant.outlined,
                  onPressed: () => showIngredientFormSheet(context),
                ),
              ],
            ),
          SizedBox(height: Space.xl),
          // Stock movements entry point lives in the FAB on compact layouts.
          if (!compact) ...[
            UiButton(
              'Stock movements log',
              icon: Icons.receipt_long_outlined,
              radius: Rounded.lg,
              variant: UiButtonVariant.tonal,
              onPressed: () => StockMovementsPage.open(context),
            ),
            SizedBox(height: Space.lg),
          ],
          ingredients.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Space.x3l),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => _message(context, 'Couldn\'t load inventory.'),
            data: (items) {
              if (items.isEmpty) {
                return _message(
                  context,
                  'No ingredients yet. Add one to start tracking stock.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final ingredient in items)
                    IngredientTile(
                      ingredient: ingredient,
                      onRestock: () =>
                          showRestockDialog(context, ingredient: ingredient),
                      onEdit: () => showIngredientFormSheet(
                        context,
                        ingredient: ingredient,
                      ),
                      onArchive: () async {
                        final repo = await ref.read(
                          ingredientRepositoryProvider.future,
                        );
                        await repo.archive(ingredient.id);
                        if (!context.mounted) return;
                        ref.read(ingredientMutationProvider.notifier).bump();
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: compact ? const InventoryExpandableFab() : null,
    );
  }

  Widget _message(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Space.x3l),
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


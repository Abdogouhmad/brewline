import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/features/admin/pages/stock_movements_page.dart';
import 'package:brewline/features/admin/providers/ingredient_actions_provider.dart';
import 'package:brewline/features/admin/widgets/ingredient_form_sheet.dart';
import 'package:brewline/features/admin/widgets/ingredient_tile.dart';
import 'package:brewline/features/admin/widgets/inventory_expandable_fab.dart';
import 'package:brewline/features/admin/widgets/restock_dialog.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_empty_state.dart';
import 'package:brewline/shared/ui/ui_page_header.dart';

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
    final ingredients = ref.watch(allIngredientsProvider);
    final compact = Breakpoints.of(context) == ScreenSize.compact;
    final l10n = AppLocalizations.of(context)!;

    final horizontal = compact ? Space.lg : Space.full;

    return Scaffold(
      body: CustomScrollView(
        // Header keeps its own padding; the list sliver reuses the same
        // horizontal gutter so the two read as one continuous column.
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              Space.lg,
              horizontal,
              Space.lg,
            ),
            sliver: SliverList.list(
              children: [
                PageHeader(
                  title: l10n.inventoryTitle,
                  subtitle: l10n.inventorySubtitle,
                  action: UiButton(
                    l10n.inventoryAddIngredient,
                    icon: Icons.add_box_rounded,
                    variant: UiButtonVariant.outlined,
                    onPressed: () => showIngredientFormSheet(context),
                  ),
                ),
                const SizedBox(height: Space.xl),
                // Stock movements entry point lives in the FAB on compact
                // layouts.
                if (!compact) ...[
                  UiButton(
                    l10n.inventoryStockMovementsLog,
                    icon: Icons.receipt_long_outlined,
                    radius: Rounded.lg,
                    variant: UiButtonVariant.tonal,
                    onPressed: () => StockMovementsPage.open(context),
                  ),
                  const SizedBox(height: Space.lg),
                ],
              ],
            ),
          ),
          ingredients.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: UiLoader(),
            ),
            error: (_, _) => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                0,
                horizontal,
                Space.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: UiErrorBanner(message: l10n.inventoryError),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: UiEmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: l10n.inventoryEmpty,
                  ),
                );
              }
              // Lazy list: tiles are built on scroll, so a long catalog
              // never forces every row into memory up front.
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, Space.lg),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final ingredient = items[index];
                    // Spacing comes from the tile's own bottom margin.
                    return IngredientTile(
                      ingredient: ingredient,
                      onRestock: () =>
                          showRestockDialog(context, ingredient: ingredient),
                      onEdit: () => showIngredientFormSheet(
                        context,
                        ingredient: ingredient,
                      ),
                      onArchive: () =>
                          ref.read(ingredientArchiveProvider).archive(
                            ingredient.id,
                          ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: compact ? const InventoryExpandableFab() : null,
    );
  }
}
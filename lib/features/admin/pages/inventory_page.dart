import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/repositories/ingredient_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/features/admin/pages/stock_movements_page.dart';
import 'package:brewline/features/admin/widgets/ingredient_form_sheet.dart';
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

    return ListView(
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
              SizedBox(height: Space.md),
              UiButton(
                'Add ingredient',
                icon: Icons.add_box_rounded,
                variant: UiButtonVariant.filled,
                onPressed: () => showIngredientFormSheet(context),
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
                variant: UiButtonVariant.filled,
                onPressed: () => showIngredientFormSheet(context),
              ),
            ],
          ),
        SizedBox(height: Space.xl),
        UiButton(
          'Stock movements log',
          icon: Icons.receipt_long_outlined,
          variant: UiButtonVariant.text,
          onPressed: () => StockMovementsPage.open(context),
        ),
        SizedBox(height: Space.lg),
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
                  _IngredientTile(
                    ingredient: ingredient,
                    onRestock: () =>
                        showRestockDialog(context, ingredient: ingredient),
                    onEdit: () async {
                      final repo = await ref.read(
                        ingredientRepositoryProvider.future,
                      );
                      final history = await repo.byId(ingredient.id);
                      if (!context.mounted) return;
                      await showIngredientFormSheet(
                        context,
                        ingredient: ingredient,
                        hasHistory: history != null,
                      );
                    },
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

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onRestock;
  final VoidCallback onEdit;
  final Future<void> Function() onArchive;

  const _IngredientTile({
    required this.ingredient,
    required this.onRestock,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final low = ingredient.isLowStock;
    final out = ingredient.isOutOfStock;
    final compact = Breakpoints.of(context) == ScreenSize.compact;

    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: Space.md),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.x2l),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(Space.lg),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Space.sm),
              decoration: BoxDecoration(
                color: out
                    ? colorScheme.errorContainer
                    : low
                    ? colorScheme.tertiaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Rounded.md),
              ),
              child: Icon(
                out
                    ? Icons.priority_high_rounded
                    : low
                    ? Icons.warning_amber_rounded
                    : Icons.inventory_2_outlined,
                size: AppSizes.iconSm,
                color: out
                    ? colorScheme.onErrorContainer
                    : low
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurfaceVariant,
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
                  SizedBox(height: 2),
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      UiText(
                        '${ingredient.currentStock} ${ingredient.unit.label} left',
                        type: UiTextType.bodySmall,
                        color: out || low
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: (out || low) ? FontWeight.w700 : null,
                      ),
                      if (out || low)
                        _StockBadge(text: out ? 'Out' : 'Low', out: out),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: Space.sm),
            if (!compact) ...[
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Archive',
                icon: const Icon(Icons.archive_outlined),
                onPressed: onArchive,
              ),
              TextButton(
                onPressed: onRestock,
                child: UiText(
                  '+ Restock',
                  type: UiTextType.labelLarge,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (value) => switch (value) {
                  'edit' => onEdit(),
                  'restock' => onRestock(),
                  'archive' => onArchive(),
                  _ => null,
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'restock',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.add_box_outlined),
                      title: Text('Restock'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.archive_outlined),
                      title: Text('Archive'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String text;
  final bool out;

  const _StockBadge({required this.text, required this.out});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = out
        ? colorScheme.errorContainer
        : colorScheme.tertiaryContainer;
    final foreground = out
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: UiText(
        text,
        type: UiTextType.labelSmall,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    );
  }
}

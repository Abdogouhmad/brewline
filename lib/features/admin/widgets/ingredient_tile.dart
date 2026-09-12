import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/status_badge.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// A card row for a single [ingredient] with restock/edit/archive actions.
/// Low/out-of-stock state is derived from live quantities and shown with a
/// stock badge mirroring the dashboard card and Inventory nav badge.
class IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onRestock;
  final VoidCallback onEdit;
  final Future<void> Function() onArchive;

  const IngredientTile({
    super.key,
    required this.ingredient,
    required this.onRestock,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
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
                        l10n.stockQuantityWithUnitLeft(
                          '${ingredient.currentStock} ${ingredient.unit.label}',
                        ),
                        type: UiTextType.bodySmall,
                        color: out || low
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                        fontWeight: (out || low) ? FontWeight.w700 : null,
                      ),
                      if (out || low)
                        _StockBadge(
                          text: out ? l10n.stockBadgeOut : l10n.stockBadgeLow,
                          out: out,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: Space.sm),
            if (!compact) ...[
              IconButton(
                tooltip: l10n.actionEdit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: l10n.actionArchive,
                icon: const Icon(Icons.archive_outlined),
                onPressed: onArchive,
              ),
              TextButton(
                onPressed: onRestock,
                child: UiText(
                  l10n.adminRestockShort,
                  type: UiTextType.labelLarge,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else
              PopupMenuButton<String>(
                tooltip: l10n.actionActions,
                onSelected: (value) => switch (value) {
                  'edit' => onEdit(),
                  'restock' => onRestock(),
                  'archive' => onArchive(),
                  _ => null,
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'restock',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.add_box_outlined),
                      title: Text(l10n.restockAction),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.actionEdit),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.archive_outlined),
                      title: Text(l10n.actionArchive),
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
    return StatusBadge(
      label: text,
      variant: out ? StatusBadgeVariant.error : StatusBadgeVariant.warning,
    );
  }
}

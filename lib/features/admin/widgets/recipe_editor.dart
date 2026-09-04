import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/ingredient_format.dart';
import 'package:brewline/core/repositories/recipe_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Embedded recipe editor used inside the admin product form.
///
/// Binds a product to the ingredients it consumes **per unit sold** — e.g.
/// "1 cup → 12 g beans, 1 cup". This is the bridge between a bulk stock buy
/// (12 kg of beans) and how many cups that yields (≈ 1000): the quantity you
/// set here is fed straight into the sale-time deduction and the low-stock
/// alerts. Products with no rows are "untracked" — selling them won't touch
/// stock (stock.md §1.3).
///
/// The parent holds a `GlobalKey<RecipeEditorState>` and calls [save] in its
/// submit handler, so the recipe persists together with the product save.
class RecipeEditor extends ConsumerStatefulWidget {
  /// The product this recipe belongs to (only meaningful in edit mode; the
  /// parent passes it so existing rows can be pre-filled). `null` in create
  /// mode — the parent passes the id when calling [RecipeEditorState.save].
  final String? productId;

  const RecipeEditor({super.key, this.productId});

  @override
  ConsumerState<RecipeEditor> createState() => RecipeEditorState();
}

class RecipeEditorState extends ConsumerState<RecipeEditor> {
  final List<_RecipeRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pid = widget.productId;
    if (pid == null) return;
    try {
      final repo = await ref.read(recipeRepositoryProvider.future);
      final recipe = await repo.getRecipeForProduct(pid);
      if (!mounted) return;
      setState(() {
        _rows.clear();
        _rows.addAll([
          for (final e in recipe)
            _RecipeRow(
              e.ingredientId,
              e.ingredientName,
              e.ingredientUnit,
              e.quantityPerUnit,
            ),
        ]);
      });
    } catch (_) {
      // Non-fatal: an empty editor is fine, the admin can re-add rows.
    }
  }

  /// Persists the current recipe for [productId] via the shared
  /// [RecipeRepository] — the single source that both this editor and the
  /// sale-time deduction read (stock.md §3.1).
  Future<void> save(String productId) async {
    final entries = <(int, int)>[
      for (final row in _rows) (row.ingredientId, row.quantity),
    ];
    await (await ref.read(recipeRepositoryProvider.future)).setRecipe(
      productId,
      entries,
    );
    ref.read(ingredientMutationProvider.notifier).bump();
  }

  void _addIngredient(Ingredient ingredient) {
    if (_rows.any((r) => r.ingredientId == ingredient.id)) return;
    setState(() {
      _rows.add(_RecipeRow(ingredient.id, ingredient.name, ingredient.unit, 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ingredients = ref.watch(allIngredientsProvider).value ?? const [];
    final available = ingredients
        .where((i) => !_rows.any((r) => r.ingredientId == i.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: UiText(
                'What does it consume per serving?',
                type: UiTextType.titleSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: Space.sm),
            Icon(
              Icons.link_rounded,
              size: AppSizes.iconSm,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        SizedBox(height: Space.xs),
        UiText(
          'Bind the product to ingredients you stock — e.g. 1 cup → 12 g '
          'beans. This drives the low-stock alerts and how many cups you can '
          'still make.',
          type: UiTextType.bodySmall,
          color: colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: Space.md),
        if (_rows.isNotEmpty) ...[
          for (var i = 0; i < _rows.length; i++) ...[
            _BindingCard(
              row: _rows[i],
              onChanged: (q) => setState(() => _rows[i].quantity = q),
              onRemove: () => setState(() => _rows.removeAt(i)),
            ),
            if (i != _rows.length - 1) SizedBox(height: Space.md),
          ],
          SizedBox(height: Space.lg),
        ],
        InputDecorator(
          decoration: InputDecoration(
            labelText: available.isEmpty
                ? 'No more ingredients left to add'
                : 'Bind an ingredient in stock',
            prefixIcon: const Icon(Icons.add_circle_outline_rounded),
          ),
          child: DropdownButton<int>(
            // Always `null`: after the chosen ingredient moves into `_rows` it
            // leaves the `available` list, so a persisted selection would go
            // stale and crash ("exactly one item with value"). Keeping the
            // value property-driven means it just resets to the hint.
            value: null,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: UiText(
              available.isEmpty
                  ? 'No more ingredients left to add'
                  : 'Select an ingredient…',
              type: UiTextType.bodyMedium,
              color: colorScheme.onSurfaceVariant,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            items: [
              for (final i in available)
                DropdownMenuItem(
                  value: i.id,
                  child: Text(
                    '${i.name} (${i.unit.label})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: available.isEmpty
                ? null
                : (value) {
                    final ing = available.firstWhere((i) => i.id == value);
                    _addIngredient(ing);
                  },
          ),
        ),
      ],
    );
  }
}

/// One bound ingredient with a "per serving" quantity and a bulk-yield hint
/// ("1 kg → ~83 cups"). On-hand stock / low-stock state deliberately not shown
/// here — those live on the Inventory tab, keeping product setup lightweight.
class _BindingCard extends StatelessWidget {
  final _RecipeRow row;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;

  const _BindingCard({
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  static const _servingNoun = 'serving';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Bulk scale for the yield hint: 1 kg for weight, 1 L for volume. Discrete
    // "units" (cups, lids) are already one-per-serving, so no bulk hint.
    final bulk = switch (row.unit) {
      IngredientUnit.grams => 1000,
      IngredientUnit.millilitres => 1000,
      IngredientUnit.units => null,
    };
    final bulkHint = bulk == null
        ? null
        : bulkYieldHint(
            bulkAmount: bulk,
            perServing: row.quantity,
            unit: row.unit,
            servingWord: _servingNoun,
          );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.lg),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: UiText(
                    row.ingredientName,
                    type: UiTextType.titleSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove binding',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 20),
                  color: colorScheme.onSurfaceVariant,
                  onPressed: onRemove,
                ),
              ],
            ),
            SizedBox(height: Space.sm),
            TextFormField(
              key: ValueKey('per_serving_${row.ingredientId}'),
              initialValue: '${row.quantity}',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Per $row.unit.label sold',
                prefixIcon: const Icon(Icons.speed_rounded),
                suffixText: row.unit.label,
              ),
              onChanged: (value) {
                final q = int.tryParse(value.trim()) ?? 0;
                onChanged(q < 0 ? 0 : q);
              },
            ),
            if (bulkHint != null) ...[
              SizedBox(height: Space.sm),
              UiText(
                bulkHint,
                type: UiTextType.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecipeRow {
  final int ingredientId;
  final String ingredientName;
  final IngredientUnit unit;
  int quantity;

  _RecipeRow(this.ingredientId, this.ingredientName, this.unit, this.quantity);
}

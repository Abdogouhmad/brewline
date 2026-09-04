import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/ingredient_format.dart';
import 'package:brewline/core/models/stock_movement.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_modal.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Opens the restock dialog for [ingredient] — enter how much arrived (in the
/// ingredient's unit) plus an optional note (supplier, PO number, …).
///
/// Restock is the one manual *increase* path; it always writes a `restock`
/// movement through [StockMovementRepository] (the single writer) so the live
/// quantity and its ledger can never disagree.
Future<void> showRestockDialog(
  BuildContext context, {
  required Ingredient ingredient,
}) {
  return showUiAdaptiveModal<void>(
    context,
    heightFactor: 0.7,
    content: _RestockForm(ingredient: ingredient),
  );
}

class _RestockForm extends ConsumerStatefulWidget {
  final Ingredient ingredient;

  const _RestockForm({required this.ingredient});

  @override
  ConsumerState<_RestockForm> createState() => _RestockFormState();
}

class _RestockFormState extends ConsumerState<_RestockForm> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  /// Enter bulk in the friendly large scale (kg/L) when the ingredient
  /// supports it, so "12 kg of beans" reads as a real cafe quantity instead of
  /// having to type 12000 grams.
  bool _large = false;

  IngredientUnit get _unit => widget.ingredient.unit;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final entered = double.tryParse(_qty.text.trim()) ?? 0;
    final qty = toBaseQuantity(value: entered, unit: _unit, large: _large);
    final adminId = ref.read(authProvider).value?.userId ?? 'admin';
    final repo = await ref.read(stockMovementRepositoryProvider.future);

    await repo.logStandalone(
      ingredientId: widget.ingredient.id,
      changeAmount: qty,
      reason: StockMovementReason.restock,
      adminId: adminId,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    ref.read(ingredientMutationProvider.notifier).bump();

    if (!mounted) return;
    Navigator.of(context).pop();
    showUiSnackBar(
      context,
      '${widget.ingredient.name} restocked (+${formatStockQuantity(qty, _unit)})',
      type: UiSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unit = _unit;
    final scaleSuffix = _large ? largeScaleLabel(unit) : unit.label;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: adaptiveModalPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_rounded, color: colorScheme.primary),
                  SizedBox(width: Space.md),
                  Expanded(
                    child: UiText(
                      'Restock ${widget.ingredient.name}',
                      type: UiTextType.titleLarge,
                      fontWeight: FontWeight.w700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Space.xs),
              UiText(
                'Currently ${formatStockQuantity(widget.ingredient.currentStock, unit)} on hand',
                type: UiTextType.bodyMedium,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: Space.xl),
              TextFormField(
                controller: _qty,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity received',
                  suffixText: scaleSuffix,
                  helperText: _large
                      ? 'Stored as ${toBaseQuantity(value: 1, unit: unit, large: true)} ${unit.label}'
                      : null,
                  prefixIcon: const Icon(Icons.add_circle_outline_rounded),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive quantity';
                  }
                  return null;
                },
              ),
              if (hasLargeScale(unit)) ...[
                SizedBox(height: Space.md),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(unit.label)),
                    ButtonSegment(
                      value: true,
                      label: Text(largeScaleLabel(unit)),
                    ),
                  ],
                  selected: {_large},
                  onSelectionChanged: (selection) {
                    setState(() => _large = selection.first);
                  },
                ),
              ],
              SizedBox(height: Space.lg),
              TextFormField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Supplier name, PO #',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                ),
              ),
              SizedBox(height: Space.xl),
              UiButton(
                _saving ? 'Restocking…' : 'Restock',
                icon: Icons.check_rounded,
                expand: true,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

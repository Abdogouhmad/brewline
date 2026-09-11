import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/ingredient.dart';
import 'package:brewline/core/models/ingredient_format.dart';
import 'package:brewline/core/repositories/ingredient_repository.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_modal.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Opens the add / edit ingredient form as a bottom sheet on phones/tablets and
/// a dialog on desktop (see [showUiAdaptiveModal]).
///
/// [ingredient] omitted → create mode; present → edit mode pre-filled.
/// `hasHistory` disables the unit field (changing it after movements exist is a
/// data-integrity foot-gun — stock.md §4.1).
Future<void> showIngredientFormSheet(
  BuildContext context, {
  Ingredient? ingredient,
  bool hasHistory = false,
}) {
  return showUiAdaptiveModal<void>(
    context,
    heightFactor: 0.92,
    content: _IngredientFormSheet(
      ingredient: ingredient,
      hasHistory: hasHistory || ingredient != null,
    ),
  );
}

class _IngredientFormSheet extends ConsumerStatefulWidget {
  final Ingredient? ingredient;

  /// When true the unit is fixed (ingredient already exists / has movements).
  final bool hasHistory;

  const _IngredientFormSheet({this.ingredient, required this.hasHistory});

  @override
  ConsumerState<_IngredientFormSheet> createState() =>
      _IngredientFormSheetState();
}

class _IngredientFormSheetState extends ConsumerState<_IngredientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _threshold;
  late IngredientUnit _unit;
  bool _saving = false;

  /// Enter the threshold in the friendly large scale (kg/L) when the unit
  /// supports it, mirroring the restock dialog — so you can type "2 kg" for
  /// beans instead of 2000 g.
  bool _thresholdLarge = false;

  /// The threshold converted to the ingredient's base unit (grams / ml / units).
  int get _thresholdValue {
    final entered = double.tryParse(_threshold.text.trim()) ?? 0;
    return toBaseQuantity(value: entered, unit: _unit, large: _thresholdLarge);
  }

  @override
  void initState() {
    super.initState();
    final ingredient = widget.ingredient;
    _name = TextEditingController(text: ingredient?.name ?? '');
    _threshold = TextEditingController(
      text: ingredient == null ? '' : '${ingredient.reorderThreshold}',
    );
    _unit = ingredient?.unit ?? IngredientUnit.grams;
  }

  @override
  void dispose() {
    _name.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final repo = await ref.read(ingredientRepositoryProvider.future);
    final existing = widget.ingredient;
    final threshold = _thresholdValue;

    if (existing == null) {
      await repo.add(
        Ingredient(
          name: _name.text.trim(),
          unit: _unit,
          reorderThreshold: threshold,
        ),
      );
    } else {
      await repo.update(
        existing.copyWith(name: _name.text.trim(), reorderThreshold: threshold),
      );
    }
    ref.read(ingredientMutationProvider.notifier).bump();

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    showUiSnackBar(
      context,
      existing == null
          ? l10n.ingredientAddedSnackbar(_name.text.trim())
          : l10n.ingredientUpdatedSnackbar(_name.text.trim()),
      type: UiSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                  Icon(
                    widget.ingredient == null
                        ? Icons.add_box_rounded
                        : Icons.edit_rounded,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: Space.md),
                  UiText(
                    widget.ingredient == null
                        ? l10n.ingredientAddTitle
                        : l10n.ingredientEditTitle,
                    type: UiTextType.titleLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              SizedBox(height: Space.xl),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.ingredientName,
                  hintText: l10n.ingredientNameHint,
                  prefixIcon: const Icon(Icons.eco_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.ingredientEnterName
                    : null,
              ),
              SizedBox(height: Space.lg),
              TextFormField(
                controller: _threshold,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.ingredientLowStockBelow,
                  suffixText: _thresholdLarge
                      ? largeScaleLabel(_unit)
                      : _unit.label,
                  helperText: _thresholdLarge
                      ? l10n.restockStoredAs(
                          '${toBaseQuantity(value: 1, unit: _unit, large: true)}',
                          _unit.label,
                        )
                      : l10n.ingredientAlertDesc,
                  prefixIcon: const Icon(Icons.notifications_active_outlined),
                ),
                validator: _nonNegative,
              ),
              if (hasLargeScale(_unit)) ...[
                SizedBox(height: Space.md),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(_unit.label)),
                    ButtonSegment(
                      value: true,
                      label: Text(largeScaleLabel(_unit)),
                    ),
                  ],
                  selected: {_thresholdLarge},
                  onSelectionChanged: (selection) {
                    final large = selection.first;
                    if (large == _thresholdLarge) return;
                    // Rescale the typed number so 2000 g ↔ 2 kg keeps its value.
                    final entered = double.tryParse(_threshold.text.trim());
                    if (entered != null && hasLargeScale(_unit)) {
                      final factor = large ? 1 / 1000 : 1000.0;
                      _threshold.text = _trimNumber(entered * factor);
                    }
                    setState(() => _thresholdLarge = large);
                  },
                ),
              ],
              SizedBox(height: Space.lg),
              if (widget.hasHistory)
                _UnitPicker(unit: _unit, enabled: false)
              else
                _UnitPicker(
                  unit: _unit,
                  enabled: true,
                  onChanged: (u) => setState(() => _unit = u),
                ),
              if (widget.hasHistory) ...[
                SizedBox(height: Space.xs),
                UiText(
                  l10n.ingredientUnitLockedNote,
                  type: UiTextType.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
              SizedBox(height: Space.xl),
              UiButton(
                _saving ? l10n.ingredientSaving : l10n.ingredientSave,
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

  String? _nonNegative(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return AppLocalizations.of(context)!.ingredientNonNegative;
    return null;
  }

  /// Formats a number without trailing zeros (e.g. `2.0` → `2`, `1.5` → `1.5`).
  static String _trimNumber(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e12) {
      return value.toInt().toString();
    }
    var out = value.toStringAsFixed(3);
    out = out.replaceFirst(RegExp(r'0+$'), '');
    out = out.replaceFirst(RegExp(r'\.$'), '');
    return out;
  }
}

class _UnitPicker extends StatelessWidget {
  final IngredientUnit unit;
  final bool enabled;
  final ValueChanged<IngredientUnit>? onChanged;

  const _UnitPicker({
    required this.unit,
    required this.enabled,
    this.onChanged,
  });

  static String _unitLabel(IngredientUnit u, AppLocalizations l10n) =>
      switch (u) {
        IngredientUnit.grams => l10n.ingredientUnitWeight,
        IngredientUnit.millilitres => l10n.ingredientUnitVolume,
        IngredientUnit.units => l10n.ingredientUnitUnits,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          l10n.ingredientTrackedUnit,
          type: UiTextType.titleSmall,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: Space.md),
        Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          children: [
            for (final u in IngredientUnit.values)
              ChoiceChip(
                label: Text(_unitLabel(u, l10n)),
                selected: unit == u,
                onSelected: enabled ? (_) => onChanged?.call(u) : null,
              ),
          ],
        ),
      ],
    );
  }
}

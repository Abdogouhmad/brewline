import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/admin/pages/stock_movements_page.dart';
import 'package:brewline/features/admin/widgets/ingredient_form_sheet.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Compact-layout speed-dial FAB: tap to reveal "Add ingredient" and
/// "Stock movements" actions, tap again (or pick one) to collapse.
class InventoryExpandableFab extends StatefulWidget {
  const InventoryExpandableFab({super.key});

  @override
  State<InventoryExpandableFab> createState() => _InventoryExpandableFabState();
}

class _InventoryExpandableFabState extends State<InventoryExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  bool _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _collapse() {
    if (!_open) return;
    setState(() => _open = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MiniFabAction(
          controller: _controller,
          index: 1,
          label: l10n.movementsTitle,
          icon: Icons.receipt_long_outlined,
          onPressed: () {
            _collapse();
            StockMovementsPage.open(context);
          },
        ),
        SizedBox(height: Space.md),
        _MiniFabAction(
          controller: _controller,
          index: 0,
          label: l10n.inventoryAddIngredient,
          icon: Icons.add_box_rounded,
          onPressed: () {
            _collapse();
            showIngredientFormSheet(context);
          },
        ),
        SizedBox(height: Space.md),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Rounded.xl),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              _open ? Icons.close_rounded : Icons.edit_rounded,
              key: ValueKey(_open),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniFabAction extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _MiniFabAction({
    required this.controller,
    required this.index,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Stagger the two mini FABs slightly so they don't pop in at once.
    final start = index * 0.1;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1.0, curve: Curves.easeOutBack),
    );

    return FadeTransition(
      opacity: controller,
      child: ScaleTransition(
        scale: animation,
        alignment: Alignment.bottomRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(right: Space.sm),
              padding: EdgeInsets.symmetric(
                horizontal: Space.sm,
                vertical: Space.xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(Rounded.md),
              ),
              child: UiText(
                label,
                type: UiTextType.labelMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
            FloatingActionButton.small(
              heroTag: 'inventory_fab_$index',
              onPressed: onPressed,
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              elevation: 2,
              child: Icon(icon),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/features/admin/widgets/product_form_sheet.dart';
import 'package:brewline/features/admin/widgets/product_table.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_page_header.dart';

/// Admin "Menu & Products" tab: the editable catalog.
///
/// Add / edit / delete products, flip in-service availability and set stock
/// levels. Every write goes through [ProductRepository] and bumps
/// [productMutationProvider], so the waiter menu and the dashboard's
/// top-sellers / low-stock cards refresh from the same source of truth.
class MenuProductsPage extends StatelessWidget {
  const MenuProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.of(context) == ScreenSize.compact;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? Space.lg : Space.full,
          vertical: Space.lg,
        ),
        children: [
          PageHeader(
            title: l10n.menuCatalogTitle,
            subtitle: l10n.menuSubtitle,
            action: UiButton(
              l10n.menuAddProduct,
              icon: Icons.add_box_rounded,
              radius: Rounded.xl,
              variant: UiButtonVariant.outlined,
              onPressed: () => showProductFormSheet(context),
            ),
          ),
          const SizedBox(height: Space.xl),
          const ProductTable(),
        ],
      ),
      floatingActionButton: compact ? _fabButton(context: context) : null,
    );
  }

  static Widget _fabButton({required BuildContext context}) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      // Same tinted family as [InventoryExpandableFab], with the app-global
      // flat elevation (the theme sets surfaces to elevation 0).
      onPressed: () => showProductFormSheet(context),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.xl),
      ),
      child: const Icon(Icons.add_rounded),
    );
  }
}
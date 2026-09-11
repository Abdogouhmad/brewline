import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/features/admin/widgets/product_form_sheet.dart';
import 'package:brewline/features/admin/widgets/product_table.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_text.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final compact = Breakpoints.of(context) == ScreenSize.compact;
    final l10n = AppLocalizations.of(context)!;

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
                  l10n.menuSubtitle,
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
                        l10n.menuCatalogTitle,
                        type: UiTextType.headlineSmall,
                        fontWeight: FontWeight.w800,
                      ),
                      SizedBox(height: Space.xs),
                      UiText(
                        l10n.menuSubtitle,
                        type: UiTextType.bodyMedium,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                UiButton(
                  l10n.menuAddProduct,
                  icon: Icons.add_box_rounded,
                  radius: Rounded.xl,
                  variant: UiButtonVariant.outlined,
                  onPressed: () => showProductFormSheet(context),
                ),
              ],
            ),
          SizedBox(height: Space.xl),
          const ProductTable(),
        ],
      ),
      floatingActionButton: compact ? _fabButton(context: context) : null,
    );
  }
}

Widget? _fabButton({required BuildContext context}) {
  final colorScheme = Theme.of(context).colorScheme;

  return FloatingActionButton(
    onPressed: () => showProductFormSheet(context),
    backgroundColor: colorScheme.primaryContainer,
    foregroundColor: colorScheme.onPrimaryContainer,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Rounded.xl),
    ),
    child: const Icon(Icons.add_rounded),
  );
}

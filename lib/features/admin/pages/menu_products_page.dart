import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/features/admin/widgets/product_form_sheet.dart';
import 'package:brewline/features/admin/widgets/product_table.dart';
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
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 600
            ? Space.lg
            : Space.full,
        vertical: Space.lg,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    'Catalog',
                    type: UiTextType.headlineSmall,
                    fontWeight: FontWeight.w800,
                  ),
                  SizedBox(height: Space.xs),
                  UiText(
                    'Manage prices, stock and availability across the menu.',
                    type: UiTextType.bodyMedium,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            UiButton(
              'Add product',
              icon: Icons.add_box_rounded,
              variant: UiButtonVariant.filled,
              onPressed: () => showProductFormSheet(context),
            ),
          ],
        ),
        SizedBox(height: Space.xl),
        const ProductTable(),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
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
                'Catalog',
                type: UiTextType.headlineSmall,
                fontWeight: FontWeight.w800,
              ),
              SizedBox(height: Space.xs),
              UiText(
                'Manage prices, stock and availability across the menu.',
                type: UiTextType.bodyMedium,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: Space.md),
              UiButton(
                'Add product',
                icon: Icons.add_box_rounded,
                variant: UiButtonVariant.filled,
                onPressed: () => showProductFormSheet(context),
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
                      'Catalog',
                      type: UiTextType.headlineSmall,
                      fontWeight: FontWeight.w800,
                    ),
                    SizedBox(height: Space.xs),
                    UiText(
                      'Manage prices, stock and availability across the menu.',
                      type: UiTextType.bodyMedium,
                      color: colorScheme.onSurfaceVariant,
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

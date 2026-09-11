import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/l10n/app_localizations.dart';
import 'package:brewline/shared/ui/ui_text.dart';

import 'dashboard_card.dart';

/// Shortcut tiles that jump to another admin tab. [onNavigate] receives the
/// destination's position in the shared admin destination list
/// (Dashboard = 0, Reports = 1, Menu = 2, Inventory = 3, Staff = 4,
/// Sales log = 5, Cashout log = 6, Settings = 7).
///
/// Redesigned as tinted action tiles (icon badge + label + short description)
/// instead of bare outlined buttons, so the most common jumps read as a
/// coherent group. Tiles flow into 1 / 2 / 3 columns by card width.
class QuickActionsRow extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const QuickActionsRow({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DashboardCard(
      title: l10n.adminDashboardQuickActions,
      icon: Icons.bolt_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 900 ? 3 : (width >= 520 ? 2 : 1);
          final columnWidth = (width - Space.sm * (columns - 1)) / columns;
          return Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              SizedBox(
                width: columnWidth,
                child: _QuickAction(
                  icon: Icons.person_add_alt_1_rounded,
                  label: l10n.adminDashboardQuickAddStaff,
                  description: l10n.adminDashboardQuickAddStaffDesc,
                  onTap: () => onNavigate(4),
                ),
              ),
              SizedBox(
                width: columnWidth,
                child: _QuickAction(
                  icon: Icons.insights_rounded,
                  label: l10n.adminDashboardQuickViewReports,
                  description: l10n.adminDashboardQuickViewReportsDesc,
                  onTap: () => onNavigate(1),
                ),
              ),
              SizedBox(
                width: columnWidth,
                child: _QuickAction(
                  icon: Icons.add_box_rounded,
                  label: l10n.adminDashboardQuickAddProduct,
                  description: l10n.adminDashboardQuickAddProductDesc,
                  onTap: () => onNavigate(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Rounded.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(Space.md),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Space.sm),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(Rounded.lg),
                ),
                child: Icon(
                  icon,
                  size: AppSizes.iconMd,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiText(
                      label,
                      type: UiTextType.titleSmall,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 2),
                    UiText(
                      description,
                      type: UiTextType.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: Space.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconSm + 4,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

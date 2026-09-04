import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/navigation/admin_destinations.dart';
import 'package:brewline/core/repositories/stock_movement_repository.dart';
import 'package:brewline/features/admin/pages/admin_dashboard_page.dart';
import 'package:brewline/features/admin/pages/admin_settings_page.dart';
import 'package:brewline/features/admin/pages/cashout_logs_page.dart';
import 'package:brewline/features/admin/pages/inventory_page.dart';
import 'package:brewline/features/admin/pages/menu_products_page.dart';
import 'package:brewline/features/admin/pages/reports_page.dart';
import 'package:brewline/features/admin/pages/sales_log_page.dart';
import 'package:brewline/features/admin/pages/staff_management_page.dart';
import 'package:brewline/shared/widgets/app_shell.dart';
import 'package:brewline/shared/widgets/nav_user_footer.dart';

/// Admin profile home: Dashboard / Reports / Menu / Inventory / Staff /
/// Sales log / Settings, navigated responsively by [AppShell].
///
/// Destination chrome (labels, icons, order) is owned by [kAdminNavItems] —
/// the "More" fold, rail and drawer all read it — while the pages themselves
/// are wired here by destination id. The Inventory destination carries a live
/// low-stock count badge on its nav item.
class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  /// Shared with [AppShell] so dashboard quick actions can switch tabs and
  /// the selected nav destination stays in sync.
  final ValueNotifier<int> _tabIndex = ValueNotifier(0);

  @override
  void dispose() {
    _tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = ref.watch(lowStockIngredientsProvider);
    final lowStockCount = lowStock.value?.length ?? 0;

    final pagesById = <String, Widget>{
      'dashboard': AdminDashboardPage(onNavigate: onNavigateTo),
      'reports': const ReportsPage(),
      'menu': const MenuProductsPage(),
      'inventory': const InventoryPage(),
      'staff': const StaffManagementPage(),
      'sales': const SalesLogPage(),
      'cashout': const CashoutLogsPage(),
      'settings': const AdminSettingsPage(),
    };

    return AppShell(
      indexController: _tabIndex,
      drawerFooter: const NavUserFooter(),
      destinations: [
        for (final item in kAdminNavItems)
          AppDestination(
            item.label,
            item.icon,
            page: pagesById[item.id],
            badgeCount: item.id == 'inventory' ? lowStockCount : null,
          ),
      ],
    );
  }

  void onNavigateTo(int index) => _tabIndex.value = index;
}

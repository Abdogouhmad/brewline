import 'package:flutter/material.dart';

import 'package:brewline/core/navigation/admin_destinations.dart';
import 'package:brewline/features/admin/pages/admin_dashboard_page.dart';
import 'package:brewline/features/admin/pages/admin_settings_page.dart';
import 'package:brewline/features/admin/pages/menu_products_page.dart';
import 'package:brewline/features/admin/pages/reports_page.dart';
import 'package:brewline/features/admin/pages/sales_log_page.dart';
import 'package:brewline/features/admin/pages/staff_management_page.dart';
import 'package:brewline/shared/widgets/app_shell.dart';
import 'package:brewline/shared/widgets/nav_user_footer.dart';

/// Admin profile home: Dashboard / Reports / Menu / Staff / Sales log /
/// Settings, navigated responsively by [AppShell].
///
/// Destination chrome (labels, icons, order) is owned by [kAdminNavItems] —
/// the "More" fold, rail and drawer all read it — while the pages themselves
/// are wired here by destination id.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
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
    final pagesById = <String, Widget>{
      'dashboard': AdminDashboardPage(onNavigate: onNavigateTo),
      'reports': const ReportsPage(),
      'menu': const MenuProductsPage(),
      'staff': const StaffManagementPage(),
      'sales': const SalesLogPage(),
      'settings': const AdminSettingsPage(),
    };

    return AppShell(
      indexController: _tabIndex,
      drawerFooter: const NavUserFooter(),
      destinations: [
        for (final item in kAdminNavItems)
          AppDestination(item.label, item.icon, page: pagesById[item.id]),
      ],
    );
  }

  void onNavigateTo(int index) => _tabIndex.value = index;
}

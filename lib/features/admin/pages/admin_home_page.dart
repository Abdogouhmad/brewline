import 'package:flutter/material.dart';

import 'package:brewline/features/admin/pages/admin_settings_page.dart';
import 'package:brewline/shared/widgets/app_shell.dart';
import 'package:brewline/widgets/shared/logout_button.dart';

/// Admin profile home.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      trailing: const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LogoutButton(),
      ),
      actions: const [LogoutButton()],
      destinations: const [
        AppDestination('Dashboard', Icons.dashboard_outlined),
        AppDestination('Staff', Icons.people_outline),
        AppDestination('Reports', Icons.bar_chart_outlined),
        AppDestination(
          'Settings',
          Icons.settings_outlined,
          page: AdminSettingsPage(),
        ),
      ],
    );
  }
}

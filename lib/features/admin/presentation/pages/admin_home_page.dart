import 'package:flutter/material.dart';

import 'package:brewline/shared/widgets/app_shell.dart';

/// Admin profile home — placeholder. Build out later; waiter is first.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      destinations: const [
        AppDestination('Dashboard', Icons.dashboard_outlined),
        AppDestination('Staff', Icons.people_outline),
        AppDestination('Reports', Icons.bar_chart_outlined),
      ],
    );
  }
}

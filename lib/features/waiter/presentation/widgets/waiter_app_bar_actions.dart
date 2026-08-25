import 'package:brewline/shared/widgets/profile_chip.dart';
import 'package:flutter/material.dart';
import 'package:brewline/features/waiter/presentation/pages/settings_page.dart';

/// AppBar actions for the waiter profile: profile badge, settings, logout.
class WaiterAppBarActions extends StatelessWidget {
  const WaiterAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        ProfileChip(),
        IconButton(
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          icon: Icon(Icons.settings_outlined),
        ),
        IconButton(
          tooltip: 'Log out',
          onPressed: null,
          icon: Icon(Icons.logout),
        ),
      ],
    );
  }
}

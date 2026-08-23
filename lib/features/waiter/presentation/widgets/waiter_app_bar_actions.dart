import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/shared/widgets/profile_chip.dart';
import 'package:flutter/material.dart';
import 'package:brewline/features/waiter/presentation/pages/settings_page.dart';

/// AppBar actions for the waiter profile: profile badge, settings, logout.
class WaiterAppBarActions extends StatelessWidget {
  const WaiterAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileChip(),
        IconButton(
          tooltip: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const _StandaloneSettingsScreen(),
              ),
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

/// Settings pushed as its own route — carries the app bar title here since
/// there is no [AppShell] app bar above it.
class _StandaloneSettingsScreen extends StatelessWidget {
  const _StandaloneSettingsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const UiText('Settings', type: UiTextType.titleLarge),
      ),
      body: const SettingsPage(),
    );
  }
}

import 'package:brewline/features/waiter/pages/settings_page.dart';
import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/shared/widgets/app_shell.dart';
import 'package:brewline/shared/widgets/brand_title.dart';
import 'package:brewline/features/waiter/widgets/waiter_app_bar_actions.dart';
import 'package:brewline/widgets/shared/logout_button.dart';

import 'menu_page.dart';
import 'orders_page.dart';

/// Waiter profile home.
/// Mobile/tablet: bottom nav shell. Desktop: split view (orders | menu)
/// with a custom app bar — no side menu.
class WaiterHomePage extends StatelessWidget {
  const WaiterHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildNavShell(),
      tablet: _buildNavShell(),
      desktop: const _DesktopWaiterHome(),
    );
  }

  Widget _buildNavShell() {
    return AppShell(
      actions: const [LogoutButton()],
      destinations: const [
        AppDestination(
          'Orders',
          Icons.receipt_long_outlined,
          page: OrdersPage(),
        ),
        AppDestination('Menu', Icons.local_cafe_outlined, page: MenuPage()),
        AppDestination(
          'Settings',
          Icons.settings_outlined,
          page: SettingsPage(),
        ),
      ],
    );
  }
}

class _DesktopWaiterHome extends StatelessWidget {
  const _DesktopWaiterHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Expanded(flex: 1, child: OrdersPage()),

          const VerticalDivider(width: 1, thickness: 0.5),

          Expanded(
            flex: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const BrandTitle(),
                toolbarHeight: responsiveValue(
                  context,
                  mobile: kToolbarHeight,
                  tablet: 64,
                  desktop: 72,
                ),
                actionsPadding: EdgeInsets.symmetric(horizontal: Space.lg),
                actions: const [WaiterAppBarActions()],
              ),
              body: const MenuPage(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/shared/ui/ui_text.dart';

class AppDestination {
  final String label;
  final IconData icon;

  /// The content shown when this tab is selected.
  /// Falls back to a centered [label] placeholder if omitted.
  final Widget? page;

  const AppDestination(this.label, this.icon, {this.page});
}

/// Responsive navigation shell shared by admin and waiter profiles:
/// bottom nav (mobile/tablet) vs extended rail (desktop).
class AppShell extends StatefulWidget {
  final List<AppDestination> destinations;
  final Widget? Function(int index)? floatingActionButtonBuilder;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> actions;

  const AppShell({
    super.key,
    required this.destinations,
    this.floatingActionButtonBuilder,
    this.leading,
    this.trailing,
    this.actions = const [],
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildNavShell(),
      desktop: _buildSidebarShell(),
    );
  }

  Widget _buildNavShell() {
    return Scaffold(
      appBar: AppBar(
        title: UiText(
          widget.destinations[_index].label,
          type: UiTextType.titleLarge,
          fontWeight: FontWeight.w700,
        ),
        actions: widget.actions,
      ),
      body: widget.destinations[_index].page ?? _placeholder(_index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in widget.destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
      floatingActionButton: widget.floatingActionButtonBuilder?.call(_index),
    );
  }

  Widget _buildSidebarShell() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: AppSizes.sidebarWidth,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            leading: widget.leading,
            trailing: widget.trailing,
            destinations: [
              for (final d in widget.destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          Expanded(
            child: widget.destinations[_index].page ?? _placeholder(_index),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButtonBuilder?.call(_index),
    );
  }

  Widget _placeholder(int index) => Center(
        child: Text(widget.destinations[index].label),
      );
}

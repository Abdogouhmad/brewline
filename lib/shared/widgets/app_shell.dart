import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/shared/ui/ui_text.dart';

class AppDestination {
  final String label;
  final IconData icon;

  /// The content shown when this tab is selected.
  /// Falls back to a centered [label] placeholder if omitted.
  final Widget? page;

  const AppDestination(this.label, this.icon, {this.page});
}

/// Responsive navigation shell shared by the admin and waiter profiles,
/// scaling the navigation pattern by `ScreenSize` (spec `improve.md` §8):
///
/// | ScreenSize | Pattern |
/// |---|---|
/// | compact (< 600) | M3 `NavigationBar` with **at most 4** slots — when
///   there are more destinations the last ones fold into a "More" sheet. |
/// | medium (600–904) | `NavigationRail` down the left edge, enough vertical
///   room for every destination. |
/// | expanded (≥ 905) | permanent `NavigationDrawer` sidebar with icon +
///   label for every destination. |
class AppShell extends StatefulWidget {
  final List<AppDestination> destinations;
  final Widget? Function(int index)? floatingActionButtonBuilder;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> actions;

  /// Optional account row pinned to the bottom of the expanded (desktop)
  /// sidebar. Pass e.g. [NavUserFooter] to surface the signed-in user +
  /// logout on the admin drawer.
  final Widget? drawerFooter;

  /// Optional external control of the selected tab (e.g. dashboard quick
  /// actions that jump straight to Staff/Reports/Menu). When omitted, the
  /// shell keeps its own internal state.
  final ValueNotifier<int>? indexController;

  const AppShell({
    super.key,
    required this.destinations,
    this.floatingActionButtonBuilder,
    this.leading,
    this.trailing,
    this.actions = const [],
    this.drawerFooter,
    this.indexController,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Folded destinations (compact, > 4 items) are shown *behind* the "More"
  /// slot; this slot index is where the selectedIndex points while one of
  /// them is active.
  static const int _moreSlot = 3;

  /// Real destinations shown directly on the compact bottom bar; the rest of
  /// the list folds into the "More" sheet (Mobile guideline: ≤ 4 slots).
  static const int _compactPrimaryCount = 3;

  late final ValueNotifier<int> _index;

  @override
  void initState() {
    super.initState();
    _index = widget.indexController ?? ValueNotifier(0);
  }

  @override
  void dispose() {
    if (widget.indexController == null) _index.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _index,
      builder: (context, index, _) => switch (Breakpoints.of(context)) {
        ScreenSize.compact => _buildCompactShell(index),
        ScreenSize.medium => _buildRailShell(index),
        ScreenSize.expanded => _buildDrawerShell(index),
      },
    );
  }

  String _titleOf(int index) => widget.destinations[index].label;

  Widget _bodyOf(int index) =>
      widget.destinations[index].page ?? _placeholder(index);

  // ---------------------------------------------------------------------------
  // Compact (phone): bottom NavigationBar, at most 4 slots + "More".
  // ---------------------------------------------------------------------------

  Widget _buildCompactShell(int index) {
    final dests = widget.destinations;
    final folded = dests.length > 4;
    // Real destinations keep the first 3 slots; slot 3 is always "More".
    final primaryCount = folded ? _compactPrimaryCount : dests.length;
    final selected = index < primaryCount ? index : _moreSlot;

    return Scaffold(
      appBar: AppBar(
        title: UiText(
          _titleOf(index),
          type: UiTextType.titleLarge,
          fontWeight: FontWeight.w700,
        ),
        actions: widget.actions,
      ),
      body: _bodyOf(index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) {
          if (folded && i == _moreSlot) {
            _openMoreSheet(primaryCount);
          } else if (i < dests.length) {
            _index.value = i;
          }
        },
        destinations: [
          for (var i = 0; i < primaryCount; i++)
            NavigationDestination(
              icon: Icon(dests[i].icon),
              label: dests[i].label,
            ),
          if (folded)
            const NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
        ],
      ),
      floatingActionButton: widget.floatingActionButtonBuilder?.call(index),
    );
  }

  /// "More" bottom sheet listing every folded destination.
  void _openMoreSheet(int primaryCount) {
    final dests = widget.destinations;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = primaryCount; i < dests.length; i++)
              ListTile(
                leading: Icon(dests[i].icon),
                title: Text(dests[i].label),
                trailing: _index.value == i
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _index.value = i;
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Medium (tablet): compact NavigationRail, every destination visible.
  // ---------------------------------------------------------------------------

  Widget _buildRailShell(int index) {
    final dests = widget.destinations;
    return Scaffold(
      appBar: AppBar(
        title: UiText(
          _titleOf(index),
          type: UiTextType.titleLarge,
          fontWeight: FontWeight.w700,
        ),
        actions: widget.actions,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => _index.value = i,
            leading: widget.leading,
            trailing: widget.trailing,
            destinations: [
              for (final d in dests)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _bodyOf(index)),
        ],
      ),
      floatingActionButton: widget.floatingActionButtonBuilder?.call(index),
    );
  }

  // ---------------------------------------------------------------------------
  // Expanded (desktop): permanent, clean sidebar — brand, nav list, user footer.
  // ---------------------------------------------------------------------------

  Widget _buildDrawerShell(int index) {
    final dests = widget.destinations;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: AppSizes.sidebarWidth,
            color: colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                _brandHeader(colorScheme),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      vertical: Space.md,
                      horizontal: Space.sm,
                    ),
                    children: [
                      for (var i = 0; i < dests.length; i++)
                        _DrawerNavItem(
                          icon: dests[i].icon,
                          label: dests[i].label,
                          selected: i == index,
                          onTap: () => _index.value = i,
                        ),
                    ],
                  ),
                ),
                if (widget.drawerFooter != null) ...[
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  Padding(
                    padding: EdgeInsets.all(Space.lg),
                    child: widget.drawerFooter,
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: _bodyOf(index)),
        ],
      ),
      floatingActionButton: widget.floatingActionButtonBuilder?.call(index),
    );
  }

  Widget _brandHeader(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.lg),
      child: Row(
        children: [
          Container(
            width: AppSizes.iconLg + 8,
            height: AppSizes.iconLg + 8,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(Rounded.lg),
            ),
            child: Icon(
              Icons.local_cafe_rounded,
              size: AppSizes.iconMd,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(width: Space.md),
          UiText(
            'brewline',
            type: UiTextType.titleMedium,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }

  Widget _placeholder(int index) =>
      Center(child: Text(widget.destinations[index].label));
}

/// Single sidebar destination: tinted pill on the active tab + dimmed label.
class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? colorScheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(Rounded.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconMd + 2,
                  color: selected ? foreground : colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: Space.lg),
                UiText(
                  label,
                  type: UiTextType.labelLarge,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: foreground,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

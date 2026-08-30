/// Responsive layout toolkit — the shared helpers behind every adaptive
/// screen in the app.
///
/// Breakpoints come from `core/responsive/breakpoints.dart` (600 / 905, the
/// canonical scale from `improve.md` §6): mobile/compact < 600, tablet/medium
/// 600–904, desktop/expanded ≥ 905. Reach for [responsiveValue] before a
/// width conditional, [ResponsiveLayout] for structurally different trees,
/// and [ResponsiveGrid] for card/tile grids.
library;

import 'package:flutter/material.dart';

import 'breakpoints.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.expanded) return DeviceType.desktop;
    if (width >= Breakpoints.medium) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;
}

/// Returns a value that scales by breakpoint. The most-used tool in the
/// codebase — reach for it before writing a conditional.
///
/// ```dart
/// padding: EdgeInsets.all(responsiveValue(context, mobile: 12, tablet: 20, desktop: 32))
/// ```
T responsiveValue<T>(
  BuildContext context, {
  required T mobile,
  T? tablet,
  required T desktop,
}) {
  final width = MediaQuery.of(context).size.width;
  if (width >= Breakpoints.expanded) return desktop;
  if (width >= Breakpoints.medium) return tablet ?? mobile;
  return mobile;
}

/// Screen-root layout switcher for structurally different layouts
/// (e.g. bottom nav vs sidebar). Use ONLY at the top of a screen's tree.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.expanded) return desktop;
        if (constraints.maxWidth >= Breakpoints.medium) return tablet ?? mobile;
        return mobile;
      },
    );
  }
}

/// Reusable responsive grid for card/tile lists — fewer/more columns by width.
///
/// Column counts and spacing are overridable per breakpoint; defaults keep
/// the original layout. Give [mainAxisExtent] a fixed tile height instead of
/// [childAspectRatio] when card content must never overflow (e.g. KPI cards).
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  /// Row height when cards have fixed-height content. When null (default),
  /// [childAspectRatio] instead drives row height.
  final double? mainAxisExtent;
  final double childAspectRatio;

  /// Column counts per breakpoint. Null falls back to [defaultColumns].
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  static const int defaultMobileColumns = 1;
  static const int defaultTabletColumns = 2;
  static const int defaultDesktopColumns = 4;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.mainAxisExtent,
    this.childAspectRatio = 1.3,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= Breakpoints.expanded
            ? desktopColumns ?? defaultDesktopColumns
            : width >= Breakpoints.medium
            ? tabletColumns ?? defaultTabletColumns
            : mobileColumns ?? defaultMobileColumns;

        final delegate = mainAxisExtent == null
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: childAspectRatio,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                mainAxisExtent: mainAxisExtent,
              );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          gridDelegate: delegate,
          itemCount: children.length,
          itemBuilder: (_, i) => children[i],
        );
      },
    );
  }
}

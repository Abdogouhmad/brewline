import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
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
  if (width >= 1024) return desktop;
  if (width >= 600) return tablet ?? mobile;
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
        if (constraints.maxWidth >= 1024) return desktop;
        if (constraints.maxWidth >= 600) return tablet ?? mobile;
        return mobile;
      },
    );
  }
}

/// Reusable responsive grid for card/tile lists — fewer/more columns by width.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.childAspectRatio = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        if (constraints.maxWidth >= 1024) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: children,
        );
      },
    );
  }
}

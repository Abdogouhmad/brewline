/// Canonical responsive breakpoints for the whole app.
///
/// Spec root: `improve.md` §6 — the same 600/905 scales the onboarding and
/// login flows use, kept here so every feature reads one source of truth
/// (`Breakpoints.of(context)`) instead of inline `MediaQuery` width checks.
library;

import 'package:flutter/widgets.dart';

/// Coarse device-width bucket shared by navigation, layouts and charts.
enum ScreenSize {
  /// < 600dp — phones. Bottom `NavigationBar`, dense grids.
  compact,

  /// 600–904dp — tablets. `NavigationRail`, 2–3 column grids.
  medium,

  /// ≥ 905dp — large tablets / desktop. `NavigationDrawer`, wide grids.
  expanded,
}

class Breakpoints {
  Breakpoints._();

  /// Material-ish scale: phones up to 599, small/medium tablets 600–904,
  /// expanded layouts from 905 (the same widths Material 3 uses).
  static const double medium = 600;
  static const double expanded = 905;

  /// Buckets [context]'s current width.
  static ScreenSize of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= expanded) return ScreenSize.expanded;
    if (w >= medium) return ScreenSize.medium;
    return ScreenSize.compact;
  }
}

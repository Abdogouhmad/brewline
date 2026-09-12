/// Canonical spacing tokens for the entire app.
///
/// Every `Padding`, `SizedBox`, and `EdgeInsets` value in the app should use
/// one of these constants (or a simple multiple), never an arbitrary number
/// chosen per-screen. This is the single source of truth for spacing rhythm,
/// matching the same "one constant, one meaning" principle applied to
/// `Breakpoints` and `Rounded`.
///
/// For backward compatibility, these alias the existing `Space` constants in
/// `core/constants/app_sizes.dart` — new code should prefer `AppSpacing` for
/// readability, but both resolve to the same values.
library;

export '../constants/app_sizes.dart' show Space;

/// Semantic spacing aliases — preferred over raw [Space] in new code.
///
/// The canonical mapping:
///   xs = 4  (micro gaps, icon padding)
///   sm = 8  (inline spacing, tight groups)
///   md = 12 (content gaps, between cards)
///   lg = 16 (section padding, field gaps)
///   xl = 24 (screen-level horizontal padding)
///   x2l = 32 (large screen margins)
///   x3l = 40 (loading states, hero spacing)
///   x4l = 48 (expansive empty states)
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double x2l = 32;
  static const double x3l = 40;
  static const double x4l = 48;
}

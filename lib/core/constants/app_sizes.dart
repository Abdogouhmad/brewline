/// Tailwind-inspired design tokens for brewline.
///
/// Use these instead of magic numbers so spacing/radius stay consistent.
library;

/// Number of digits in the PIN keypad (shared by admin and staff).
const int kAdminPinLength = 4;

/// Alias — prefer [kAdminPinLength] for new code; kept for backward compat.
const int kStaffPinLength = kAdminPinLength;

class Space {
  Space._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double x2l = 32;
  static const double x3l = 40;
  static const double x4l = 48;
  static const double full = 64;
}

class Rounded {
  Rounded._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double x2l = 24;
  static const double x3l = 32;
  static const double full = 9999;
}

class AppSizes {
  AppSizes._();

  /// Minimum interactive target size (accessibility).
  static const double tapTarget = 48;

  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;

  static const double borderWidth = 1;

  /// Max content width on wide screens so layouts don't stretch forever.
  static const double maxContentWidth = 1200;

  /// Sidebar width on desktop shells.
  static const double sidebarWidth = 240;
}

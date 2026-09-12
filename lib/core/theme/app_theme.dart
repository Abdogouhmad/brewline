import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:brewline/core/constants/app_sizes.dart';

/// Fallback seed color when the platform can't provide a dynamic scheme
/// (e.g. Linux, older Android). Coffee-brown to match the brand.
const Color kSeedColor = Color(0xFF6F4E37);

/// Spec-named alias for the single canonical fallback seed constant
/// (feat.md §1 — the only allowed hardcoded hex in the codebase).
const Color kBrandSeedColor = kSeedColor;

ThemeData buildLightTheme(ColorScheme? dynamicScheme) {
  final colorScheme =
      dynamicScheme ?? ColorScheme.fromSeed(seedColor: kSeedColor);
  return _baseTheme(colorScheme);
}

ThemeData buildDarkTheme(ColorScheme? dynamicScheme) {
  final colorScheme =
      dynamicScheme ??
      ColorScheme.fromSeed(seedColor: kSeedColor, brightness: Brightness.dark);
  return _baseTheme(colorScheme);
}

ThemeData _baseTheme(ColorScheme colorScheme) {
  final textTheme = GoogleFonts.soraTextTheme().apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
      thickness: 1,
      space: 1,
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      dataRowMinHeight: 52,
      dataRowMaxHeight: 64,
      headingRowHeight: 56,
      horizontalMargin: Space.lg,
      headingTextStyle: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        letterSpacing: 0,
      ),
    ),
  );
}

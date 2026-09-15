import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:brewline/core/constants/app_sizes.dart';

/// Fallback seed color when the platform can't provide a dynamic scheme
/// (e.g. Linux, older Android). Coffee-brown to match the brand.
const Color kSeedColor = Color(0xFF6F4E37);

/// Spec-named alias for the single canonical fallback seed constant
/// (feat.md §1 — the only allowed hardcoded hex in the codebase).
const Color kBrandSeedColor = kSeedColor;

/// Corner profile mandated by feat.md §1: 24dp for large *surfaces*
/// (cards, dialogs, sheets) and 16dp for *fields and buttons*.
const double _surfaceRadius = Rounded.x2l;
const double _fieldRadius = Rounded.xl;

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

  final borderRadius = BorderRadius.circular(_surfaceRadius);
  final roundedShape = RoundedRectangleBorder(borderRadius: borderRadius);
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(_fieldRadius),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // M3 expressive ripple — a soft, gradient ink splash instead of the
    // flat Material ripple. Falls back gracefully where unsupported.
    splashFactory: InkSparkle.splashFactory,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    // App-wide motion: fine-grained hover/press overlays + smooth page
    // transitions built on the M3 expressive curves.
    pageTransitionsTheme: PageTransitionsTheme(
      builders: const {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
      },
    ),

    // -------------------------------------------------------------------------
    // Surfaces — cards, dialogs, sheets share one 24dp radius + flat outline.
    // -------------------------------------------------------------------------
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: roundedShape,
      clipBehavior: Clip.antiAlias,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: colorScheme.outlineVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_surfaceRadius)),
      ),
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(_fieldRadius)),
      ),
    ),

    // -------------------------------------------------------------------------
    // Buttons — 16dp radius, M3 hover/pressed overlays, no drop shadow.
    // -------------------------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_fieldRadius),
          ),
        ),
        // Subtle hover + pressed tint that follows the color scheme instead
        // of the default grey overlay.
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? colorScheme.primary.withValues(alpha: 0.08)
              : states.contains(WidgetState.pressed)
              ? colorScheme.primary.withValues(alpha: 0.12)
              : null,
        ),
      ),
    ),

    // -------------------------------------------------------------------------
    // Inputs — 16dp outlined fields matching AppTextField.
    // -------------------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      border: fieldBorder.copyWith(borderSide: BorderSide(color: colorScheme.outline)),
      enabledBorder:
          fieldBorder.copyWith(borderSide: BorderSide(color: colorScheme.outline)),
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder:
          fieldBorder.copyWith(borderSide: BorderSide(color: colorScheme.error)),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => textTheme.bodyMedium?.copyWith(
          color: states.contains(WidgetState.error)
              ? colorScheme.error
              : colorScheme.primary,
        ) ?? const TextStyle(),
      ),
    ),

    // -------------------------------------------------------------------------
    // Navigation — M3 bars/rails/drawers with colour-scheme-tinted indicators.
    // -------------------------------------------------------------------------
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
      ),
      labelTextStyle: WidgetStateTextStyle.resolveWith(
        (states) => textTheme.labelMedium?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
        ) ?? const TextStyle(),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
      ),
      selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelType: NavigationRailLabelType.all,
    ),

    // -------------------------------------------------------------------------
    // Feedback — snackbars, chips, progress, switches, segmented controls.
    // -------------------------------------------------------------------------
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: colorScheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.lg),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.secondaryContainer,
      labelStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      secondarySelectedColor: colorScheme.secondaryContainer,
      iconTheme: IconThemeData(color: colorScheme.primary, size: AppSizes.iconMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.full),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceContainerHighest,
      circularTrackColor: colorScheme.surfaceContainerHighest,
    ),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith(
        (states) => Icon(
          Icons.circle,
          size: AppSizes.iconSm,
          color: states.contains(WidgetState.selected)
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(Rounded.sm),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onInverseSurface),
      waitDuration: const Duration(milliseconds: 400),
      showDuration: const Duration(milliseconds: 900),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 1,
      hoverElevation: 3,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
    ),

    // -------------------------------------------------------------------------
    // Menus / pickers.
    // -------------------------------------------------------------------------
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainer),
        elevation: const WidgetStatePropertyAll(4),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surfaceContainer,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
    ),

    // -------------------------------------------------------------------------
    // Divider + DataTable (existing consolidated tokens).
    // -------------------------------------------------------------------------
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
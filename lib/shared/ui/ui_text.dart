import 'package:flutter/material.dart';

/// Semantic text style selector mapped to the app [TextTheme].
enum UiTextType {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

extension UiTextTypeX on UiTextType {
  TextStyle? of(TextTheme theme) => switch (this) {
    UiTextType.displayLarge => theme.displayLarge,
    UiTextType.displayMedium => theme.displayMedium,
    UiTextType.displaySmall => theme.displaySmall,
    UiTextType.headlineLarge => theme.headlineLarge,
    UiTextType.headlineMedium => theme.headlineMedium,
    UiTextType.headlineSmall => theme.headlineSmall,
    UiTextType.titleLarge => theme.titleLarge,
    UiTextType.titleMedium => theme.titleMedium,
    UiTextType.titleSmall => theme.titleSmall,
    UiTextType.bodyLarge => theme.bodyLarge,
    UiTextType.bodyMedium => theme.bodyMedium,
    UiTextType.bodySmall => theme.bodySmall,
    UiTextType.labelLarge => theme.labelLarge,
    UiTextType.labelMedium => theme.labelMedium,
    UiTextType.labelSmall => theme.labelSmall,
  };
}

/// Theme-aware text widget. Picks a base style from [type] (defaults to
/// `bodyMedium`), applies [colorScheme.onSurface] when no explicit color is
/// given, then merges any overrides from [style].
///
/// ```dart
/// UiText('BrewLine', type: UiTextType.headlineMedium, fontWeight: FontWeight.w700)
/// ```
class UiText extends StatelessWidget {
  final String text;
  final UiTextType type;
  final TextStyle? style;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  final double? letterSpacing;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;

  const UiText(
    this.text, {
    super.key,
    this.type = UiTextType.bodyMedium,
    this.style,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.letterSpacing,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = type.of(theme.textTheme) ?? const TextStyle();

    // Explicit [color] always wins; otherwise fall back to the theme style's
    // own color (already brightness-aware via app_theme), then onSurface.
    TextStyle effective = base.copyWith(
      color: color ?? base.color ?? theme.colorScheme.onSurface,
      fontWeight: fontWeight,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    );

    if (style != null) effective = effective.merge(style);

    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
      style: effective,
    );
  }
}

import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';

enum UiButtonVariant { filled, tonal, outlined, text }

/// M3 button that scales padding, min size and text style by device type.
///
/// ```dart
/// UiButton('Add to order', icon: Icons.add, onPressed: () {})
/// ```
class UiButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final UiButtonVariant variant;
  final bool expand;
  final Color? foreground;
  final Color? background;

  const UiButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.variant = UiButtonVariant.filled,
    this.expand = false,
    this.foreground,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry padding = responsiveValue(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.md),
      tablet: const EdgeInsets.symmetric(horizontal: Space.x2l, vertical: Space.lg),
      desktop: const EdgeInsets.symmetric(horizontal: Space.full, vertical: Space.lg),
    );

    final double minHeight = responsiveValue(
      context,
      mobile: AppSizes.tapTarget,
      tablet: 52,
      desktop: 56,
    );

    final TextStyle textStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
          fontSize: responsiveValue(context, mobile: 14.0, desktop: 16.0),
          fontWeight: FontWeight.w600,
        );

    ButtonStyle base = switch (variant) {
      UiButtonVariant.filled => FilledButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: background,
          elevation: 0,
        ),
      UiButtonVariant.tonal => FilledButton.styleFrom(
          foregroundColor: foreground ?? Theme.of(context).colorScheme.secondary,
          backgroundColor: background ?? Theme.of(context).colorScheme.secondaryContainer,
          elevation: 0,
        ),
      UiButtonVariant.outlined => OutlinedButton.styleFrom(
          foregroundColor: foreground,
        ),
      UiButtonVariant.text => TextButton.styleFrom(foregroundColor: foreground),
    };

    final style = base.copyWith(
      padding: WidgetStatePropertyAll(padding),
      minimumSize: WidgetStatePropertyAll(Size(expand ? double.infinity : 0, minHeight)),
      textStyle: WidgetStatePropertyAll(textStyle),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rounded.xl)),
      ),
    );

    final button = switch (variant) {
      UiButtonVariant.text when icon != null => TextButton.icon(
          onPressed: onPressed,
          style: style,
          icon: Icon(icon),
          label: Text(label),
        ),
      UiButtonVariant.text => TextButton(
          onPressed: onPressed,
          style: style,
          child: Text(label),
        ),
      UiButtonVariant.outlined when icon != null => OutlinedButton.icon(
          onPressed: onPressed,
          style: style,
          icon: Icon(icon),
          label: Text(label),
        ),
      UiButtonVariant.outlined => OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: Text(label),
        ),
      _ when icon != null => FilledButton.icon(
          onPressed: onPressed,
          style: style,
          icon: Icon(icon),
          label: Text(label),
        ),
      _ => FilledButton(
          onPressed: onPressed,
          style: style,
          child: Text(label),
        ),
    };

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/design/motion.dart';
import 'package:brewline/core/responsive/responsive.dart';

enum UiButtonVariant { filled, tonal, outlined, text, destructive }

/// M3 button that scales padding, min size and text style by device type, with
/// an expressive press micro-interaction (the container "sinks" slightly).
///
/// ```dart
/// UiButton('Add to order', icon: Icons.add, onPressed: () {})
/// ```
class UiButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final UiButtonVariant variant;
  final bool expand;
  final Color? foreground;
  final Color? background;
  final double? radius;

  const UiButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.variant = UiButtonVariant.filled,
    this.expand = false,
    this.foreground,
    this.background,
    this.radius,
  });

  @override
  State<UiButton> createState() => _UiButtonState();
}

class _UiButtonState extends State<UiButton> {
  bool _pressed = false;

  void _onPressChange(bool pressed) {
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry padding = responsiveValue(
      context,
      mobile: const EdgeInsets.symmetric(
        horizontal: Space.xl,
        vertical: Space.md,
      ),
      tablet: const EdgeInsets.symmetric(
        horizontal: Space.x2l,
        vertical: Space.lg,
      ),
      desktop: const EdgeInsets.symmetric(
        horizontal: Space.full,
        vertical: Space.lg,
      ),
    );

    final double minHeight = responsiveValue(
      context,
      mobile: AppSizes.tapTarget,
      tablet: 52,
      desktop: 56,
    );

    final TextStyle textStyle = Theme.of(context).textTheme.labelLarge!
        .copyWith(
          fontSize: responsiveValue(context, mobile: 14.0, desktop: 16.0),
          fontWeight: FontWeight.w600,
        );

    ButtonStyle base = switch (widget.variant) {
      UiButtonVariant.filled => FilledButton.styleFrom(
        foregroundColor: widget.foreground,
        backgroundColor: widget.background,
        elevation: 0,
      ),
      UiButtonVariant.tonal => FilledButton.styleFrom(
        foregroundColor:
            widget.foreground ?? Theme.of(context).colorScheme.secondary,
        backgroundColor:
            widget.background ?? Theme.of(context).colorScheme.secondaryContainer,
        elevation: 0,
      ),
      UiButtonVariant.destructive => FilledButton.styleFrom(
        foregroundColor:
            widget.foreground ?? Theme.of(context).colorScheme.onError,
        backgroundColor: widget.background ?? Theme.of(context).colorScheme.error,
        elevation: 0,
      ),
      UiButtonVariant.outlined => OutlinedButton.styleFrom(
        foregroundColor: widget.foreground,
      ),
      UiButtonVariant.text => TextButton.styleFrom(
        foregroundColor: widget.foreground,
      ),
    };

    final style = base.copyWith(
      padding: WidgetStatePropertyAll(padding),
      minimumSize: WidgetStatePropertyAll(
        Size(widget.expand ? double.infinity : 0, minHeight),
      ),
      textStyle: WidgetStatePropertyAll(textStyle),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.radius ?? Rounded.xl),
        ),
      ),
    );

    final button = switch (widget.variant) {
      UiButtonVariant.text when widget.icon != null => TextButton.icon(
        onPressed: widget.onPressed,
        style: style,
        icon: Icon(widget.icon),
        label: Text(widget.label),
      ),
      UiButtonVariant.text => TextButton(
        onPressed: widget.onPressed,
        style: style,
        child: Text(widget.label),
      ),
      UiButtonVariant.outlined when widget.icon != null => OutlinedButton.icon(
        onPressed: widget.onPressed,
        style: style,
        icon: Icon(widget.icon),
        label: Text(widget.label),
      ),
      UiButtonVariant.outlined => OutlinedButton(
        onPressed: widget.onPressed,
        style: style,
        child: Text(widget.label),
      ),
      _ when widget.icon != null => FilledButton.icon(
        onPressed: widget.onPressed,
        style: style,
        icon: Icon(widget.icon),
        label: Text(widget.label),
      ),
      _ => FilledButton(
        onPressed: widget.onPressed,
        style: style,
        child: Text(widget.label),
      ),
    };

    final wrapped = Listener(
      // Pointer-driven press tracking (safe across rebuilds — unlike a
      // [WidgetStatesController], which fires listeners during the button's
      // own build). Disabled buttons ignore presses entirely.
      onPointerDown: widget.onPressed == null
          ? null
          : (_) => _onPressChange(true),
      onPointerUp: widget.onPressed == null
          ? null
          : (_) => _onPressChange(false),
      onPointerCancel: widget.onPressed == null
          ? null
          : (_) => _onPressChange(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.shortest,
        curve: AppMotion.standard,
        child: button,
      ),
    );

    if (widget.expand) {
      return SizedBox(width: double.infinity, child: wrapped);
    }
    return wrapped;
  }
}
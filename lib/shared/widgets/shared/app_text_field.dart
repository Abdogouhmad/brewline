import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';

/// Canonical M3-styled text field for the app.
///
/// Rounded 16dp outlined border, label + inline error slot, dynamic
/// color from the current [ColorScheme].
class AppTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onChanged: onChanged,
      obscureText: obscureText,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rounded.xl),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rounded.xl),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rounded.xl),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rounded.xl),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Rounded.xl),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.md,
        ),
      ),
    );
  }
}

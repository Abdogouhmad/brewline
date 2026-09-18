import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';

import 'ui_text.dart';

/// Full-width primary submit button with an embedded loading spinner.
///
/// Sizes responsively (52 / 60 / 64dp tall) and disables itself while
/// [loading] so the shared form actions (login, onboarding) stay consistent.
class UiSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final double? minHeight;

  const UiSubmitButton(
    this.label, {
    super.key,
    this.loading = false,
    this.onPressed,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(
          minHeight ??
              responsiveValue(context, mobile: 52, tablet: 60, desktop: 64),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rounded.xl),
        ),
      ),
      child: loading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : UiText(
              label,
              type: UiTextType.titleMedium,
              fontWeight: FontWeight.w700,
            ),
    );
  }
}
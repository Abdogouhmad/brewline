import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';

import 'ui_text.dart';

/// Centered, error-coloured inline message shown under a form field / button.
///
/// Wraps the recurring `SizedBox + UiText(... error)` pair so forms don't
/// repeat it by hand four times per screen.
class UiInlineError extends StatelessWidget {
  final String message;

  /// Which [UiTextType] renders the message (defaults to `bodySmall`).
  final UiTextType type;

  /// Breathing room above the message.
  final double paddingTop;

  const UiInlineError(
    this.message, {
    super.key,
    this.type = UiTextType.bodySmall,
    this.paddingTop = Space.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: paddingTop),
      child: UiText(
        message,
        type: type,
        color: Theme.of(context).colorScheme.error,
        textAlign: TextAlign.center,
      ),
    );
  }
}
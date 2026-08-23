import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'ui_text.dart';

enum UiSnackBarType { info, success, warning, error }

/// Shows a themed, M3-style snack bar.
///
/// ```dart
/// showUiSnackBar(context, 'Order charged', type: UiSnackBarType.success);
/// ```
void showUiSnackBar(
  BuildContext context,
  String message, {
  UiSnackBarType type = UiSnackBarType.info,
  String? label,
  IconData? icon,
  VoidCallback? onLabelPressed,
  Duration duration = const Duration(seconds: 3),
}) {
  final colorScheme = Theme.of(context).colorScheme;

  final (background, foreground, defaultIcon) = switch (type) {
    UiSnackBarType.info => (
      colorScheme.inverseSurface,
      colorScheme.onInverseSurface,
      Icons.info_outline_rounded,
    ),
    UiSnackBarType.success => (
      colorScheme.primaryContainer,
      colorScheme.onPrimaryContainer,
      Icons.check_circle_outline_rounded,
    ),
    UiSnackBarType.warning => (
      colorScheme.tertiaryContainer,
      colorScheme.onTertiaryContainer,
      Icons.warning_amber_rounded,
    ),
    UiSnackBarType.error => (
      colorScheme.errorContainer,
      colorScheme.onErrorContainer,
      Icons.error_outline_rounded,
    ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? defaultIcon, color: foreground, size: AppSizes.iconMd),
            SizedBox(width: Space.md),
            Expanded(
              child: UiText(
                message,
                type: UiTextType.bodyMedium,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        elevation: 0,
        margin: EdgeInsets.all(Space.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rounded.lg),
        ),
        duration: duration,
        action: label == null
            ? null
            : SnackBarAction(
                label: label,
                textColor: foreground,
                onPressed: onLabelPressed ?? () {},
              ),
      ),
    );
}

import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Consistent empty state widget used across Sales Log, Cashout Logs,
/// Stock Movements log, and any list that can legitimately have zero items.
///
/// Replaces the ad-hoc `_message(...)` builders in ~10 dashboard card
/// widgets and the `_emptyState` patterns in paged list screens.
///
/// ```dart
/// if (items.isEmpty)
///   UiEmptyState(
///     icon: Icons.receipt_long_rounded,
///     message: l10n.salesLogEmpty,
///   )
/// ```
class UiEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const UiEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x3l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            SizedBox(height: Space.lg),
            UiText(
              message,
              type: UiTextType.bodyMedium,
              color: colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: Space.lg),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent loading indicator for list/table views.
///
/// Replaces ~15 identical `Center(CircularProgressIndicator())` wrapped
/// in `Padding(EdgeInsets.all(Space.x3l))` patterns across the app.
///
/// ```dart
/// if (_loading && items.isEmpty) const UiLoader()
/// ```
class UiLoader extends StatelessWidget {
  final String? message;

  const UiLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x3l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              SizedBox(height: Space.lg),
              UiText(
                message!,
                type: UiTextType.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent inline error banner using [ColorScheme.errorContainer].
///
/// Replaces ad-hoc error styling scattered across the app with one
/// shared pattern that automatically adapts to dynamic color.
///
/// ```dart
/// UiErrorBanner(message: l10n.loginIncorrectPin)
/// ```
class UiErrorBanner extends StatelessWidget {
  final String message;

  const UiErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(Rounded.xl),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: AppSizes.iconMd,
            color: colorScheme.onErrorContainer,
          ),
          SizedBox(width: Space.md),
          Expanded(
            child: UiText(
              message,
              type: UiTextType.bodySmall,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

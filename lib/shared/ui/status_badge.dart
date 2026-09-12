import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Semantic variants for [StatusBadge], each mapped to the matching
/// [ColorScheme] container / on-container pair.
///
/// Replaces ad-hoc `_RefundBadge`, `_StockBadge`, `_DeltaChip`,
/// `_StatusPill`, `_roleBadge`, and profile-pill badge implementations
/// scattered across the codebase with one shared, consistent pill.
enum StatusBadgeVariant {
  /// Success / positive outcome (e.g. "Up to date", active shift).
  success,

  /// Warning / attention needed (e.g. "Low stock", partial refund).
  warning,

  /// Error / critical state (e.g. "Out of stock", voided, failed check).
  error,

  /// Informational / neutral (e.g. role badge, flat delta).
  info,

  /// Accent / brand-colored variant (e.g. "Beta", update available).
  accent,
}

/// Consistent status pill used across the entire app.
///
/// Uses the current [ColorScheme]'s container/on-container pairs so it
/// automatically adapts to dynamic color and dark/light mode.
///
/// ```dart
/// StatusBadge(label: 'Low stock', variant: StatusBadgeVariant.warning)
/// ```
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;
  final bool outlined;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.info,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (:foreground, :background) = _resolveColors(colorScheme);

    if (outlined) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Rounded.full),
          border: Border.all(color: foreground.withValues(alpha: 0.45)),
        ),
        child: _content(foreground),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: _content(foreground),
    );
  }

  Widget _content(Color foreground) {
    final children = <Widget>[
      UiText(
        label,
        type: UiTextType.labelSmall,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    ];

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: foreground),
          SizedBox(width: Space.xs),
          ...children,
        ],
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  ({Color foreground, Color background}) _resolveColors(ColorScheme scheme) =>
      switch (variant) {
        StatusBadgeVariant.success => (
          foreground: scheme.onPrimaryContainer,
          background: scheme.primaryContainer,
        ),
        StatusBadgeVariant.warning => (
          foreground: scheme.onTertiaryContainer,
          background: scheme.tertiaryContainer,
        ),
        StatusBadgeVariant.error => (
          foreground: scheme.onErrorContainer,
          background: scheme.errorContainer,
        ),
        StatusBadgeVariant.info => (
          foreground: scheme.onSecondaryContainer,
          background: scheme.secondaryContainer,
        ),
        StatusBadgeVariant.accent => (
          foreground: scheme.onPrimaryContainer,
          background: scheme.primaryContainer,
        ),
      };
}

/// A live/idle dot indicator — used for shift status, online indicators, etc.
///
/// Replaces the ad-hoc `_liveDot` in `shift_status_card.dart` and any
/// similar colored-dot patterns.
class LiveDot extends StatelessWidget {
  final Color color;
  final double size;

  const LiveDot({super.key, required this.color, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

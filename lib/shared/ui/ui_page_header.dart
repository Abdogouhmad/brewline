import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';

import 'ui_text.dart';

/// Shared page header: a large [title] over a [subtitle].
///
/// On non-compact screens an optional [action] (e.g. an "Add" button) sits on
/// the right, top-aligned. Both compact and expanded layouts always show the
/// full title + subtitle so the screen keeps an explicit heading (compact
/// relies on a FAB for its primary action).
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = Breakpoints.of(context) == ScreenSize.compact;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          title,
          type: UiTextType.headlineSmall,
          fontWeight: FontWeight.w800,
        ),
        const SizedBox(height: Space.xs),
        UiText(
          subtitle,
          type: UiTextType.bodyMedium,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );

    if (compact || action == null) return heading;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: heading),
        SizedBox(width: Space.lg),
        action!,
      ],
    );
  }
}
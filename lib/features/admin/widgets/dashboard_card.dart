import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Titled rounded container used to group dashboard sections (charts, lists,
/// alerts) with a consistent visual frame.
class DashboardCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;

  const DashboardCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // The visual frame (flat fill, outline border, radius, zero margin) comes
    // from the app-wide `cardTheme` — this widget only tunes the padding and
    // header layout.
    final colorScheme = Theme.of(context).colorScheme;
    final padding = Breakpoints.of(context) == ScreenSize.compact
        ? EdgeInsets.all(Space.md)
        : EdgeInsets.all(Space.lg);

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: AppSizes.iconSm + 4,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: Space.sm),
                ],
                Expanded(
                  child: UiText(
                    title,
                    type: UiTextType.titleMedium,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?trailing,
              ],
            ),
            SizedBox(
              height: Breakpoints.of(context) == ScreenSize.compact
                  ? Space.md
                  : Space.lg,
            ),
            child,
          ],
        ),
      ),
    );
  }
}

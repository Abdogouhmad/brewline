import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'ui_text.dart';

/// M3 expressive card with an optional image, title, subtitle and an
/// action row. Scales its paddings and image height per device type.
///
/// ```dart
/// UiCard(
///   image: Image.asset('assets/latte.png', fit: BoxFit.cover),
///   title: 'Flat White',
///   subtitle: 'Double shot · whole milk',
///   actions: [UiText('\$4.50', fontWeight: FontWeight.w700)],
///   onTap: () {},
/// )
/// ```
class UiCard extends StatelessWidget {
  final Widget? image;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final Color? background;
  final EdgeInsetsGeometry? padding;

  /// Tighter paddings for dense grids (menu cards, small tiles).
  final bool compact;

  const UiCard({
    super.key,
    required this.title,
    this.image,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.onTap,
    this.background,
    this.padding,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: background ?? colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.x2l),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: image!,
              ),
            Padding(
              padding: padding ??
                  EdgeInsets.all(
                    compact
                        ? Space.md
                        : responsiveValue(
                            context,
                            mobile: Space.lg,
                            tablet: Space.xl,
                            desktop: Space.xl,
                          ),
                  ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: Space.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          title,
                          type: UiTextType.titleMedium,
                          fontWeight: FontWeight.w600,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          SizedBox(height: Space.xs),
                          UiText(
                            subtitle!,
                            type: UiTextType.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? Space.md : Space.lg,
                  0,
                  compact ? Space.md : Space.lg,
                  compact ? Space.sm : Space.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) SizedBox(width: Space.sm),
                      actions[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return Semantics(button: onTap != null, child: card);
  }
}

import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';

import 'ui_text.dart';

/// M3 expressive card with an optional image, title, subtitle, an arbitrary
/// [content] body and an action row. Scales its paddings and image height per
/// device type.
///
/// ```dart
/// UiCard(
///   title: 'Flat White',
///   leading: const UiListAvatar(icon: Icons.people_outline),
///   subtitle: 'Double shot · whole milk',
///   content: Row(children: [ /* ... */ ]),
///   actions: [UiText('\$4.50', fontWeight: FontWeight.w700)],
///   onTap: () {},
/// )
/// ```
class UiCard extends StatelessWidget {
  final Widget? image;
  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Arbitrary body shown between the title block and the [actions] row.
  /// Lets [UiCard] host dense layouts (filter rows, tables, forms) while
  /// keeping the shared card shell and paddings.
  final Widget? content;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final Color? background;

  /// Overrides the title colour (e.g. faded text for inactive rows).
  final Color? titleColor;
  final EdgeInsetsGeometry? padding;

  /// Tighter paddings for dense grids (menu cards, small tiles).
  final bool compact;

  const UiCard({
    super.key,
    required this.title,
    this.image,
    this.subtitle,
    this.leading,
    this.content,
    this.actions = const [],
    this.onTap,
    this.background,
    this.titleColor,
    this.padding,
    this.compact = false,
  });

  /// Closes [content] with the same bottom inset the [actions] row would use,
  /// so a content-only card doesn't look bottom-heavy.
  double get _contentBottom => actions.isEmpty
      ? (compact ? Space.md : Space.lg)
      : (compact ? Space.sm : Space.lg);

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
            if (image != null) AspectRatio(aspectRatio: 16 / 9, child: image!),
            Padding(
              padding:
                  padding ??
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
                  if (leading != null) ...[leading!, SizedBox(width: Space.md)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          title,
                          type: UiTextType.titleMedium,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            if (content != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? Space.md : Space.lg,
                  Space.xs,
                  compact ? Space.md : Space.lg,
                  _contentBottom,
                ),
                child: content,
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

import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/design/motion.dart';
import 'package:brewline/core/responsive/responsive.dart';

import 'ui_text.dart';

/// M3 expressive card with an optional image, title, subtitle, an arbitrary
/// [content] body and an action row. Scales its paddings and image height per
/// device type.
///
/// On desktop the card reacts expressively to the pointer: a soft branded
/// shadow lifts it on hover and it scales down slightly while pressed —
/// feedback that makes tappable surfaces feel alive without breaking the flat,
/// outlined look.
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
class UiCard extends StatefulWidget {
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
  State<UiCard> createState() => _UiCardState();
}

class _UiCardState extends State<UiCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final raised = _pressed || _hovered;
    final tappable = widget.onTap != null;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      elevation: raised ? 2 : 0,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
      color: widget.background ?? colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rounded.x2l),
        side: BorderSide(
          color: _hovered
              ? colorScheme.primary.withValues(alpha: 0.55)
              : colorScheme.outlineVariant,
        ),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: tappable
            ? (value) => setState(() => _pressed = value)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.image != null)
              AspectRatio(aspectRatio: 16 / 9, child: widget.image!),
            Padding(
              padding:
                  widget.padding ??
                  EdgeInsets.all(
                    widget.compact
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
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: Space.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiText(
                          widget.title,
                          type: UiTextType.titleMedium,
                          fontWeight: FontWeight.w600,
                          color: widget.titleColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: Space.xs),
                          UiText(
                            widget.subtitle!,
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
            if (widget.content != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.compact ? Space.md : Space.lg,
                  Space.xs,
                  widget.compact ? Space.md : Space.lg,
                  widget._contentBottom,
                ),
                child: widget.content,
              ),
            if (widget.actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.compact ? Space.md : Space.lg,
                  0,
                  widget.compact ? Space.md : Space.lg,
                  widget.compact ? Space.sm : Space.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < widget.actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: Space.sm),
                      widget.actions[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      button: tappable,
      child: MouseRegion(
        cursor: tappable ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: tappable ? (_) => setState(() => _hovered = true) : null,
        onExit: tappable ? (_) => setState(() => _hovered = false) : null,
        // Subtle press compression — the expressive M3 "sink" micro-motion.
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: AppMotion.short,
          curve: AppMotion.standard,
          child: card,
        ),
      ),
    );
  }
}
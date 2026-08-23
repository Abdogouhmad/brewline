import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'ui_text.dart';

/// Section wrapper with an uppercase header, used to group [UiListGroup]s.
class UiListSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const UiListSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: Space.sm,
            bottom: Space.md,
          ),
          child: UiText(
            title.toUpperCase(),
            type: UiTextType.labelLarge,
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        ...children,
      ],
    );
  }
}

/// A rounded container that groups [UiListTile]s, M3-style.
class UiListGroup extends StatelessWidget {
  final List<Widget> children;
  final bool useCard;
  final String? header;
  final String? footer;

  const UiListGroup({
    super.key,
    required this.children,
    this.useCard = true,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget group = Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: Space.xl,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          children[i],
        ],
      ],
    );

    if (useCard) {
      group = Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rounded.xl),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: group,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) ...[
          Padding(
            padding: EdgeInsets.only(left: Space.md, bottom: Space.sm),
            child: UiText(header!, type: UiTextType.labelMedium),
          ),
        ],
        group,
        if (footer != null) ...[
          SizedBox(height: Space.sm),
          Padding(
            padding: EdgeInsets.only(left: Space.md),
            child: UiText(
              footer!,
              type: UiTextType.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: Space.lg),
      ],
    );
  }
}

/// Responsive M3 list tile supporting the app's core row patterns:
///
/// - `title & subtitle | trailing`
/// - `title & subtitle | price | action icon (delete order)`
/// - `leading avatar | title & subtitle | trailing widget`
class UiListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Optional price shown before [trailing] in a fixed-width column so
  /// rows stay aligned.
  final String? price;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onActionPressed;
  final VoidCallback? onTap;
  final bool outlined;

  const UiListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.price,
    this.actionIcon,
    this.actionTooltip,
    this.onActionPressed,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dense = Responsive.isDesktop(context);

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: dense ? Space.xs : Space.sm,
      ),
      minVerticalPadding: Space.md,
      leading: leading ??
          (outlined
              ? CircleAvatar(
                  radius: AppSizes.iconMd / 2 + 4,
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  child: Icon(actionIcon ?? Icons.circle, size: AppSizes.iconMd),
                )
              : null),
      title: UiText(
        title,
        type: UiTextType.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      subtitle: subtitle == null || subtitle!.isEmpty
          ? null
          : UiText(
              subtitle!,
              type: UiTextType.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (price != null)
            Padding(
              padding: EdgeInsets.only(right: Space.md),
              child: UiText(
                price!,
                type: UiTextType.titleSmall,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ?trailing,          if (actionIcon != null && onActionPressed != null)
            IconButton(
              tooltip: actionTooltip,
              onPressed: onActionPressed,
              icon: Icon(actionIcon),
              color: colorScheme.error,
            )
          else if (actionIcon != null && onTap == null)
            Icon(actionIcon, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Leading avatar icon helper for [UiListTile].
class UiListAvatar extends StatelessWidget {
  final IconData icon;
  final Color? background;
  final Color? foreground;

  const UiListAvatar({super.key, required this.icon, this.background, this.foreground});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 20,
      backgroundColor: background ?? colorScheme.surfaceContainerHighest,
      foregroundColor: foreground ?? colorScheme.primary,
      child: Icon(icon, size: AppSizes.iconMd),
    );
  }
}

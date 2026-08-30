import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/breakpoints.dart';
import 'package:brewline/features/auth/providers/current_user_provider.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Profile pill bound to [currentUserProvider] (auth session + `staff` row).
/// Shows initials avatar + display name + role. Hidden while logged out or
/// the profile is still resolving (e.g. right after sign-in).
///
/// Role badge is dropped and the name ellipsised on phone widths so the
/// top bar never overflows.
class ProfileChip extends ConsumerWidget {
  final VoidCallback? onTap;

  const ProfileChip({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final narrow = Breakpoints.of(context) == ScreenSize.compact;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Rounded.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: UiText(
                  user.initials,
                  type: UiTextType.labelSmall,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: Space.sm),
              Flexible(
                child: UiText(
                  user.name,
                  type: UiTextType.labelLarge,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!narrow) ...[
                SizedBox(width: Space.xs),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Space.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(Rounded.full),
                  ),
                  child: UiText(
                    user.role,
                    type: UiTextType.labelSmall,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

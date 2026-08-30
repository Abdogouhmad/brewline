import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/user_role.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/auth/providers/auth_state.dart';
import 'package:brewline/shared/ui/ui_text.dart';
import 'package:brewline/widgets/shared/logout_button.dart';

/// Compact account row pinned to the bottom of the expanded (desktop) sidebar:
/// avatar + the signed-in user's label and role, with a logout shortcut.
///
/// Bound to the live [authProvider] session, so it always reflects who is on
/// shift. Renders nothing while logged out (e.g. pre-login test assembly).
///
/// ```dart
/// AppShell(
///   drawerFooter: const NavUserFooter(),
///   // ...
/// )
/// ```
class NavUserFooter extends ConsumerWidget {
  const NavUserFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).value;
    if (session == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final roleLabel = session.role == Role.admin
        ? 'Administrator'
        : 'Staff member';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: UiText(
                _initials(session),
                type: UiTextType.labelLarge,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UiText(
                    session.username,
                    type: UiTextType.titleSmall,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  UiText(
                    roleLabel,
                    type: UiTextType.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Log out',
              onPressed: () => confirmLogout(context, ref),
              icon: Icon(
                Icons.logout_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _initials(AuthState session) {
    final first = session.username.isEmpty
        ? '?'
        : session.username[0].toUpperCase();
    return session.role == Role.admin ? '${first}A' : first;
  }
}

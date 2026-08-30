import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/features/auth/login_page.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';

/// Shared logout confirm: shows the dialog (so an accidental tap on a shared
/// café device can't silently end a session), clears the session via
/// [authProvider] and pushes [LoginPage] with the whole navigation stack
/// cleared ([pushAndRemoveUntil]) so the user can never back-button into an
/// authenticated screen.
///
/// Both [LogoutButton] (app bar) and [LogoutListTile] (Settings) mount the
/// same single source of truth for this flow.
Future<void> confirmLogout(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onLoggedOut,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to sign in again to take orders.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;
  onLoggedOut?.call();
  await ref.read(authProvider.notifier).logout();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

/// App-bar logout action shared by the admin and waiter dashboards (top bar).
class LogoutButton extends ConsumerWidget {
  /// If provided, called just before navigation fires — use it for
  /// screen-specific cleanup (e.g. clearing an in-progress order draft).
  final VoidCallback? onLoggedOut;

  const LogoutButton({super.key, this.onLoggedOut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout),
      onPressed: () => confirmLogout(context, ref, onLoggedOut: onLoggedOut),
    );
  }
}

/// Full-width destructive logout row for Settings pages — a Material 3
/// [ListTile] with the error accent, reusing the same [confirmLogout] dialog.
class LogoutListTile extends ConsumerWidget {
  const LogoutListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(Icons.logout_rounded, color: colorScheme.error),
      title: Text(
        'Log out',
        style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'End this session on the device.',
        style: TextStyle(color: colorScheme.error.withValues(alpha: 0.7)),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.error),
      onTap: () => confirmLogout(context, ref),
    );
  }
}

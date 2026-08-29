import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/features/auth/login_page.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';

/// App-bar logout action shared by the admin and waiter dashboards.
///
/// On tap it shows a small confirm dialog (so an accidental tap on a shared
/// café device can't silently end a session); on confirm it clears the session
/// via [authProvider] and pushes [LoginPage] with the whole navigation stack
/// cleared ([pushAndRemoveUntil]) so the user can never back-button into an
/// authenticated screen.
class LogoutButton extends ConsumerWidget {
  /// If provided, called just before navigation fires — use it for
  /// screen-specific cleanup (e.g. clearing an in-progress order draft).
  final VoidCallback? onLoggedOut;

  const LogoutButton({super.key, this.onLoggedOut});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout),
      onPressed: () => _confirm(context, ref),
    );
  }
}

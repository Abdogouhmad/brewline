import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:brewline/features/onboarding/pages/onboarding_page.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/shared/ui/ui_text.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const UiText('Settings', type: UiTextType.titleLarge),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: EdgeInsets.all(Space.xl),
            children: [
              Card(
                elevation: 0,
                color: colorScheme.errorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Rounded.x2l),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: Space.xl,
                    vertical: Space.sm,
                  ),
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.onErrorContainer,
                  ),
                  title: UiText(
                    'Reset onboarding',
                    type: UiTextType.titleMedium,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onErrorContainer,
                  ),
                  subtitle: UiText(
                    'Clear admin data and return to the setup screen.',
                    type: UiTextType.bodySmall,
                    color: colorScheme.onErrorContainer,
                  ),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: () => _confirmReset(context, ref),
                    child: const Text('Reset'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset onboarding?'),
        content: const Text(
          'This will delete the admin account and return you to the setup screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove('onboarding_complete');
      ref.invalidate(onboardingCompleteProvider);

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
          (_) => false,
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/shared/ui/ui_modal.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Opens the update action sheet/dialog — the same responsive shell reused
/// across platforms. On desktop (≥ 905dp) it renders as a centred dialog, on
/// phones/tablets as a bottom sheet, driven entirely by [showUiAdaptiveModal]
/// with no platform branching here.
Future<void> showUpdateActionSheet(BuildContext context) {
  return showUiAdaptiveModal<void>(
    context,
    heightFactor: 0.7,
    content: const UpdateActionSheet(),
  );
}

class UpdateActionSheet extends ConsumerWidget {
  const UpdateActionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final updater = ref.watch(updateProvider);

    return Padding(
      padding: adaptiveModalPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.system_update_alt_rounded,
            size: AppSizes.iconLg + 16,
            color: updater.isMandatory
                ? colorScheme.tertiary
                : colorScheme.primary,
          ),
          SizedBox(height: Space.sm),
          UiText(
            updater.isMandatory ? 'Update required' : 'Software update',
            type: UiTextType.headlineSmall,
            fontWeight: FontWeight.w800,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Space.lg),
          _body(context, ref, updater),
          SizedBox(height: Space.xl),
          _actions(context, ref, updater),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, UpdateState updater) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (updater.status) {
      case UpdateStatus.checking:
        return const Padding(
          padding: EdgeInsets.only(top: Space.lg),
          child: Column(
            children: [
              SizedBox(
                width: AppSizes.iconLg + 8,
                height: AppSizes.iconLg + 8,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: Space.lg),
              UiText('Checking for updates…', textAlign: TextAlign.center),
            ],
          ),
        );

      case UpdateStatus.downloading:
        final progress = (updater.progress ?? 0) * 100;
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Rounded.full),
              child: LinearProgressIndicator(
                value: updater.progress ?? 0,
                minHeight: 8,
              ),
            ),
            SizedBox(height: Space.md),
            UiText(
              'Downloading… ${progress.toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Space.md),
            UiText(
              'The update is verified by checksum before it is installed.',
              type: UiTextType.bodySmall,
              color: colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case UpdateStatus.readyToInstall:
        return Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: colorScheme.primary,
              size: AppSizes.iconLg + 8,
            ),
            SizedBox(height: Space.md),
            UiText(
              'Ready to install. The app will close and relaunch.',
              textAlign: TextAlign.center,
            ),
          ],
        );

      case UpdateStatus.error:
        return Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.error,
              size: AppSizes.iconLg + 8,
            ),
            SizedBox(height: Space.md),
            UiText(
              updater.error ?? 'An error occurred while checking for updates.',
              type: UiTextType.bodyMedium,
              color: colorScheme.error,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case UpdateStatus.available:
      case UpdateStatus.idle:
        final notes = updater.manifest?.releaseNotes ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UiText(
              updater.hasUpdate
                  ? 'A new version of BrewLine is available.'
                  : 'BrewLine is up to date.',
              type: UiTextType.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (notes.isNotEmpty) ...[
              SizedBox(height: Space.lg),
              UiText(
                'What’s new',
                type: UiTextType.titleSmall,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: Space.sm),
              UiText(
                notes,
                type: UiTextType.bodyMedium,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
            if (!updater.hasUpdate) ...[
              SizedBox(height: Space.lg),
              UiText(
                'You’re running the latest build for this device.',
                type: UiTextType.bodySmall,
                color: colorScheme.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
    }
  }

  Widget _actions(BuildContext context, WidgetRef ref, UpdateState updater) {
    final canDownload =
        updater.hasUpdate && updater.status == UpdateStatus.available;
    final isDownloading =
        updater.status == UpdateStatus.downloading ||
            updater.status == UpdateStatus.checking ||
            updater.status == UpdateStatus.readyToInstall;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                isDownloading || updater.status == UpdateStatus.error
                    ? null
                    : () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
        if (canDownload || updater.status == UpdateStatus.readyToInstall) ...[
          SizedBox(width: Space.md),
          Expanded(
            child: FilledButton.icon(
              onPressed: isDownloading && !canDownload
                  ? null
                  : () {
                      ref
                          .read(updateProvider.notifier)
                          .downloadAndInstall();
                    },
              icon: const Icon(Icons.download_rounded),
              label: Text(
                updater.status == UpdateStatus.readyToInstall
                    ? 'Install now'
                    : 'Update now',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Full-screen, non-dismissible takeover shown when a **mandatory** update is
/// available. Blocks usage of the entire app (no back button, no navigation)
/// until the update is installed — the only way forward is to download.
///
/// Works identically on every platform; the shell is driven by the same
/// [updateProvider] state machine the settings action sheet uses.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final updater = ref.watch(updateProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Space.x2l),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      updater.status == UpdateStatus.error
                          ? Icons.error_outline_rounded
                          : Icons.system_security_update_warning_rounded,
                      size: AppSizes.iconLg * 2,
                      color: updater.status == UpdateStatus.error
                          ? colorScheme.error
                          : colorScheme.tertiary,
                    ),
                    SizedBox(height: Space.xl),
                    UiText(
                      'Upgrade required',
                      type: UiTextType.headlineMedium,
                      fontWeight: FontWeight.w800,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Space.lg),
                    UiText(
                      'BrewLine needs to be updated before you can continue. '
                      'This version is no longer supported.',
                      type: UiTextType.bodyMedium,
                      color: colorScheme.onSurfaceVariant,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: Space.xl),
                    ..._statusBody(context, updater),
                    SizedBox(height: Space.xl),
                    _downloadButton(context, ref, updater),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _statusBody(BuildContext context, UpdateState updater) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (updater.status) {
      case UpdateStatus.checking:
        return [
          const SizedBox(
            width: AppSizes.iconLg + 8,
            height: AppSizes.iconLg + 8,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: Space.lg),
          const UiText('Checking…', textAlign: TextAlign.center),
        ];

      case UpdateStatus.downloading:
        final progress = (updater.progress ?? 0) * 100;
        return [
          SizedBox(
            width: AppSizes.iconLg * 2,
            height: AppSizes.iconLg * 2,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: updater.progress ?? 0,
                  strokeWidth: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: colorScheme.primary,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: UiText(
                    '${progress.toStringAsFixed(0)}%',
                    type: UiTextType.titleSmall,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          UiText(
            'Downloading…',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.md),
          UiText(
            'Your update is verified by checksum before it is applied.',
            type: UiTextType.bodySmall,
            color: colorScheme.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
        ];

      case UpdateStatus.readyToInstall:
        return [
          Icon(
            Icons.check_circle_outline_rounded,
            color: colorScheme.primary,
            size: AppSizes.iconLg * 2,
          ),
          const SizedBox(height: Space.md),
          const UiText(
            'Ready to install. The app will close and relaunch.',
            textAlign: TextAlign.center,
          ),
        ];

      case UpdateStatus.error:
        return [
          Container(
            padding: EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(Rounded.lg),
            ),
            child: Column(
              children: [
                UiText(
                  updater.error ?? 'The update could not be downloaded.',
                  type: UiTextType.bodyMedium,
                  color: colorScheme.onErrorContainer,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.sm),
                UiText(
                  'Check your internet connection and try again.',
                  type: UiTextType.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ];

      case UpdateStatus.available:
      case UpdateStatus.idle:
        final notes = updater.manifest?.releaseNotes ?? '';
        final lines =
            notes
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toList();
        return [
          if (notes.isNotEmpty) ...[
            UiText(
              'What’s new',
              type: UiTextType.titleSmall,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: Space.sm),
            for (final line in lines)
              Padding(
                padding: EdgeInsets.only(bottom: Space.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: Space.xs),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: UiText(
                        _stripBullet(line),
                        type: UiTextType.bodyMedium,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ];
    }
  }

  static String _stripBullet(String line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
      return trimmed.substring(2);
    }
    return line;
  }

  Widget _downloadButton(BuildContext context, WidgetRef ref, UpdateState updater) {
    final busy = updater.status == UpdateStatus.downloading ||
        updater.status == UpdateStatus.checking ||
        updater.status == UpdateStatus.readyToInstall;
    final failed = updater.status == UpdateStatus.error;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
      ),
      onPressed: busy ? null : () {
        ref.read(updateProvider.notifier).downloadAndInstall();
      },
      icon: failed ? const Icon(Icons.refresh_rounded) : const Icon(Icons.download_rounded),
      label: UiText(
        updater.status == UpdateStatus.readyToInstall
            ? 'Install now'
            : failed
            ? 'Retry'
            : 'Download update',
        type: UiTextType.titleSmall,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
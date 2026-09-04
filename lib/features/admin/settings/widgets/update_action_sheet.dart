import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/updates/update_manifest.dart';
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
    final isBeta = kUpdateChannel == UpdateChannel.beta;

    return Padding(
      padding: adaptiveModalPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.system_update_alt_rounded,
                size: AppSizes.iconLg + 16,
                color: updater.isMandatory
                    ? colorScheme.tertiary
                    : colorScheme.primary,
              ),
              if (isBeta)
                Positioned(
                  right: 0,
                  top: 0,
                  child: _BetaBadge(colorScheme: colorScheme),
                ),
            ],
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
        return _DownloadProgressBody(progress: updater.progress ?? 0);

      case UpdateStatus.readyToInstall:
        return _ReadyToInstallBody();

      case UpdateStatus.error:
        return _ErrorBody(message: updater.error);

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
              _ReleaseNotesList(notes: notes),
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

/// Determinate circular progress with the live percentage shown as a number.
class _DownloadProgressBody extends StatelessWidget {
  final double progress;

  const _DownloadProgressBody({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).clamp(0, 100);

    return Column(
      children: [
        SizedBox(
          width: AppSizes.iconLg * 2.5,
          height: AppSizes.iconLg * 2.5,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: UiText(
                  '${percent.toStringAsFixed(0)}%',
                  type: UiTextType.titleMedium,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Space.md),
        UiText(
          'Downloading…',
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
  }
}

/// Distinct success state before handing off to install: an animated
/// checkmark so the admin gets a clear "this worked" moment rather than the
/// sheet just disappearing.
class _ReadyToInstallBody extends StatelessWidget {
  const _ReadyToInstallBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SuccessCheck(),
        SizedBox(height: Space.md),
        UiText(
          'Download complete. The app will close and relaunch to install.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Gently scales the checkmark in so the success lands with a small flourish,
/// matching M3 Expressive's tactile motion language rather than a hard cut.
class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();

  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..forward();
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.check_circle_rounded,
        color: colorScheme.primary,
        size: AppSizes.iconLg * 2,
      ),
    );
  }
}

/// Error state styled with `errorContainer` (non-alarming) rather than a
/// jarring red flash, consistent with how validation errors render elsewhere.
class _ErrorBody extends StatelessWidget {
  final String? message;

  const _ErrorBody({this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(Rounded.lg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: AppSizes.iconLg,
          ),
          SizedBox(height: Space.md),
          UiText(
            message ?? 'An error occurred while checking for updates.',
            type: UiTextType.bodyMedium,
            color: colorScheme.onErrorContainer,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Render `releaseNotes` as a real bulleted list (split on newlines) instead
/// of one raw text block — reads much better for multi-line release notes.
class _ReleaseNotesList extends StatelessWidget {
  final String notes;

  const _ReleaseNotesList({required this.notes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lines =
        notes
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                SizedBox(width: Space.md),
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
    );
  }

  /// Removes a leading markdown dash/bullet if present, so copying notes with
  /// `- ` or `• ` prefixes doesn't double-print a bullet.
  static String _stripBullet(String line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('- ') || trimmed.startsWith('• ')) {
      return trimmed.substring(2);
    }
    return line;
  }
}

class _BetaBadge extends StatelessWidget {
  final ColorScheme colorScheme;

  const _BetaBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.md, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(Rounded.full),
      ),
      child: UiText(
        'Beta',
        type: UiTextType.labelSmall,
        fontWeight: FontWeight.w700,
        color: colorScheme.onTertiaryContainer,
      ),
    );
  }
}

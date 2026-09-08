import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';
import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/update_installer.dart' show UpdateCheckResult;
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/core/utils/date_format.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Full-page OTA update screen, reachable from the "Update" entry in both the
/// admin and waiter settings (pushed as a nested route).
///
/// Gives the terminal operator a single dedicated surface for everything
/// update-related: a status header (up-to-date / new update banner), a version
/// details card (current vs latest, platform, download size), a "What's new"
/// changelog card and the primary download/install action with live progress.
///
/// Drives the same [updateProvider] state machine as the action sheet and the
/// mandatory-update takeover, so it stays in sync with auto-checks and forced
/// updates already performed elsewhere.
class UpdateScreen extends ConsumerStatefulWidget {
  const UpdateScreen({super.key});

  @override
  ConsumerState<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends ConsumerState<UpdateScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-check on entry only if no result has been computed yet, so opening
    // the screen never forces a redundant network round-trip right after an
    // auto-check already surfaced an update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(updateProvider);
      if (state.status == UpdateStatus.idle && state.checkResult == null) {
        ref.read(updateProvider.notifier).checkForUpdates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const UiText('App update', type: UiTextType.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                responsiveValue(context, mobile: Space.lg, desktop: Space.full),
                Space.lg,
                responsiveValue(context, mobile: Space.lg, desktop: Space.full),
                Space.x2l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusHeader(state: state),
                  SizedBox(height: Space.x2l),
                  if (state.status == UpdateStatus.checking) ...[
                    const _CheckingCard(),
                  ] else ...[
                    if (state.status == UpdateStatus.error ||
                        state.checkResult == UpdateCheckResult.checkFailed) ...[
                      _ErrorCard(
                        message: state.status == UpdateStatus.error
                            ? state.error
                            : 'Could not check for updates. Check the network '
                                  'connection and try again.',
                      ),
                      SizedBox(height: Space.lg),
                    ],
                    _VersionCard(state: state),
                    if (state.hasUpdate ||
                        (state.release?.releaseNotes ?? '').isNotEmpty) ...[
                      SizedBox(height: Space.lg),
                      _ChangelogCard(notes: state.release?.releaseNotes ?? ''),
                    ],
                    SizedBox(height: Space.x2l),
                    switch (state.status) {
                      UpdateStatus.downloading => _DownloadCard(
                        progress: state.progress ?? 0,
                      ),
                      UpdateStatus.readyToInstall => _ReadyCard(
                        onChangePressed: () => notifier.downloadAndInstall(),
                      ),
                      _ => _Actions(
                        canUpdate: state.hasUpdate &&
                            state.status != UpdateStatus.downloading &&
                            state.status != UpdateStatus.readyToInstall,
                        failed: state.status == UpdateStatus.error,
                        onCheck: () => notifier.checkForUpdates(),
                        onDownload: () => notifier.downloadAndInstall(),
                      ),
                    },
                  ],
                  SizedBox(height: Space.lg),
                  const _AutoCheckToggle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero banner: circular illustration + a status pill ("New update available"
/// or "You are up to date").
class _StatusHeader extends StatelessWidget {
  final UpdateState state;

  const _StatusHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final failed = state.status == UpdateStatus.error ||
        state.checkResult == UpdateCheckResult.checkFailed;
    final update = state.hasUpdate &&
        state.status != UpdateStatus.error &&
        !failed;
    final checking = state.status == UpdateStatus.checking;

    final accent = failed
        ? colorScheme.error
        : checking
        ? colorScheme.secondaryContainer
        : update
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final accentFg = failed
        ? colorScheme.onError
        : checking
        ? colorScheme.onSecondaryContainer
        : update
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    return Column(
      children: [
        // Concentric circles with a status icon in the middle.
        SizedBox(
          width: responsiveValue(context, mobile: 120.0, desktop: 140.0),
          height: responsiveValue(context, mobile: 120.0, desktop: 140.0),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: responsiveValue(context, mobile: 104.0, desktop: 120.0),
                  height:
                      responsiveValue(context, mobile: 104.0, desktop: 120.0),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: responsiveValue(context, mobile: 84.0, desktop: 96.0),
                  height: responsiveValue(context, mobile: 84.0, desktop: 96.0),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    checking
                        ? Icons.sync_rounded
                        : failed
                        ? Icons.error_outline_rounded
                        : update
                        ? Icons.system_update_alt_rounded
                        : Icons.check_circle_outline_rounded,
                    size: responsiveValue(context, mobile: 40.0, desktop: 46.0),
                    color: accentFg,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Space.lg),
        _StatusPill(
          checking: checking,
          update: update,
          failed: failed,
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool checking;
  final bool update;
  final bool failed;

  const _StatusPill({
    required this.checking,
    required this.update,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (Color color, String label) = checking
        ? (colorScheme.primary, 'Checking for updates…')
        : failed
        ? (colorScheme.error, 'Update check failed')
        : update
        ? (colorScheme.primary, 'New update available')
        : (Colors.green.shade600, 'You are up to date');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Rounded.full),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (checking)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          SizedBox(width: Space.md),
          UiText(
            label,
            type: UiTextType.labelLarge,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Loading card shown while the initial check is in flight.
class _CheckingCard extends StatelessWidget {
  const _CheckingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(
          width: AppSizes.iconLg + 8,
          height: AppSizes.iconLg + 8,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        SizedBox(height: Space.lg),
        UiText(
          'Contacting the update server…',
          type: UiTextType.bodyMedium,
          color: colorScheme.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Error card for a failed check/download.
class _ErrorCard extends StatelessWidget {
  final String? message;

  const _ErrorCard({this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(Rounded.xl),
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

/// Current vs latest version card with platform + download size.
class _VersionCard extends ConsumerWidget {
  final UpdateState state;

  const _VersionCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfo = ref.watch(appInfoProvider).value;

    final current = appInfo?.version ?? '…';
    final latest = _latestVersion(state);
    final size = _downloadSizeMB(state);

    return _Card(
      title: 'Version details',
      icon: Icons.smartphone_rounded,
      children: [
        _InfoRow(icon: Icons.layers_rounded, label: 'Current version', value: 'v$current'),
        _divider(context),
        _InfoRow(
          icon: Icons.new_releases_outlined,
          label: 'Latest version',
          value: latest == null ? 'Unknown' : 'v$latest',
          highlight: state.hasUpdate,
        ),
        if (state.hasUpdate && size != null) ...[
          _divider(context),
          _InfoRow(
            icon: Icons.insert_drive_file_outlined,
            label: 'Download size',
            value: size,
          ),
        ],
        _divider(context),
        _InfoRow(
          icon: Icons.schedule_rounded,
          label: 'Last checked',
          value: _lastCheckedLabel(context, ref),
        ),
        _divider(context),
        _InfoRow(
          icon: Icons.rule_rounded,
          label: 'Last result',
          value: _resultLabel(ref),
          highlight: _lastResult(ref) == UpdateCheckResult.checkFailed,
        ),
      ],
    );
  }

  /// "Never" when no check has ever completed, else the formatted timestamp.
  static String _lastCheckedLabel(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastUpdateCheckProvider);
    if (last == null) return 'Never';
    return formatDateWithTime(last);
  }

  static UpdateCheckResult? _lastResult(WidgetRef ref) =>
      ref.watch(lastUpdateCheckResultProvider);

  /// Human label for the persisted outcome of the most recent check, so a
  /// failed background check is visible ("failed") instead of looking "new".
  static String _resultLabel(WidgetRef ref) {
    return switch (_lastResult(ref)) {
      UpdateCheckResult.upToDate => 'Up to date',
      UpdateCheckResult.updateAvailable => 'Update available',
      UpdateCheckResult.updateMandatory => 'Update required',
      UpdateCheckResult.checkFailed => 'Check failed',
      null => 'Never checked',
    };
  }

  static String? _latestVersion(UpdateState state) {
    final release = state.release;
    if (release == null) return null;
    return release.version;
  }

  static String? _downloadSizeMB(UpdateState state) {
    final size = state.asset?.sizeBytes;
    if (size == null) return null;
    if (size >= 1 << 20) return '${(size / (1 << 20)).toStringAsFixed(1)} MB';
    if (size >= 1 << 10) {
      return '${(size / (1 << 10)).toStringAsFixed(0)} KB';
    }
    return '$size B';
  }
}

Widget _divider(BuildContext context) => Divider(
  height: 1,
  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
);

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Space.md),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconMd, color: colorScheme.onSurfaceVariant),
          SizedBox(width: Space.lg),
          UiText(
            label,
            type: UiTextType.bodyMedium,
            color: colorScheme.onSurfaceVariant,
          ),
          const Spacer(),
          UiText(
            value,
            type: UiTextType.bodyMedium,
            fontWeight: FontWeight.w700,
            color: highlight ? colorScheme.primary : colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}

/// "What's new" card rendering the release notes from the GitHub release body.
///
/// Handles the CHANGELOG markdown subset the workflow ships in the release:
/// `### Added/Changed/Fixed/...` section headings render as tinted sub-headers,
/// `- bullet` lines render as bulleted rows, and any other line renders as plain
/// body text. Inline `**bold**` emphasis is preserved everywhere.
class _ChangelogCard extends StatelessWidget {
  final String notes;

  const _ChangelogCard({required this.notes});

  static final RegExp _headingRe = RegExp(r'^#{1,3}\s+(.*)$');
  static final RegExp _bulletRe = RegExp(r'^[-•*]\s+(.*)$');
  static final RegExp _boldRe = RegExp(r'\*\*(.+?)\*\*');

  @override
  Widget build(BuildContext context) {
    final lines =
        notes
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    return _Card(
      title: "What's new",
      icon: Icons.new_releases_outlined,
      children: [
        if (lines.isEmpty)
          UiText(
            'No release notes available for this release.',
            type: UiTextType.bodyMedium,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            style: const TextStyle(fontStyle: FontStyle.italic),
          )
        else
          for (var i = 0; i < lines.length; i++) _row(context, lines[i], i),
      ],
    );
  }

  Widget _row(BuildContext context, String line, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    final heading = _headingRe.firstMatch(line);
    if (heading != null) {
      return Padding(
        padding: EdgeInsets.only(top: index == 0 ? 0 : Space.lg, bottom: Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(Rounded.full),
              ),
            ),
            SizedBox(width: Space.md),
            Expanded(
              child: UiText(
                heading.group(1)!,
                type: UiTextType.titleSmall,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    final bullet = _bulletRe.firstMatch(line);
    if (bullet != null) {
      return Padding(
        padding: EdgeInsets.only(bottom: Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: Space.xs + 2),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: Space.md),
            Expanded(
              child: _RichText(
                text: bullet.group(1)!,
                type: UiTextType.bodyMedium,
                color: colorScheme.onSurfaceVariant,
                boldColor: colorScheme.onSurface,
                boldWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: Space.sm),
      child: _RichText(
        text: line,
        type: UiTextType.bodyMedium,
        color: colorScheme.onSurfaceVariant,
        boldColor: colorScheme.onSurface,
        boldWeight: FontWeight.w700,
      ),
    );
  }
}

/// Body text that renders `**bold**` markdown spans as bold while keeping the
/// rest of the line in the given style/color defaults.
class _RichText extends StatelessWidget {
  final String text;
  final UiTextType type;
  final Color color;
  final Color boldColor;
  final FontWeight boldWeight;

  const _RichText({
    required this.text,
    required this.type,
    required this.color,
    required this.boldColor,
    required this.boldWeight,
  });

  @override
  Widget build(BuildContext context) {
    final base = (type.of(Theme.of(context).textTheme) ??
            const TextStyle()).copyWith(color: color);

    final spans = <TextSpan>[];
    int last = 0;
    for (final m in _ChangelogCard._boldRe.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(
        TextSpan(
          text: m.group(1),
          style: TextStyle(color: boldColor, fontWeight: boldWeight),
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    if (spans.isEmpty) spans.add(TextSpan(text: text));

    return Text.rich(TextSpan(style: base, children: spans));
  }
}

/// Download progress with a determinate linear bar + percentage.
class _DownloadCard extends StatelessWidget {
  final double progress;

  const _DownloadCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = ((progress * 100).clamp(0, 100)).toStringAsFixed(0);

    return _Card(
      title: 'Downloading update…',
      icon: Icons.download_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UiText(
              'Download in progress',
              type: UiTextType.bodyMedium,
              color: colorScheme.onSurfaceVariant,
            ),
            UiText(
              '$percent%',
              type: UiTextType.titleSmall,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ],
        ),
        SizedBox(height: Space.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(Rounded.full),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ),
        SizedBox(height: Space.md),
        UiText(
          'The update is verified by checksum before it is installed. '
          'Please do not close the app.',
          type: UiTextType.bodySmall,
          color: colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

/// Ready-to-install success state with the handoff CTA.
class _ReadyCard extends StatelessWidget {
  final VoidCallback onChangePressed;

  const _ReadyCard({required this.onChangePressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: AppSizes.iconLg * 2),
        SizedBox(height: Space.md),
        UiText(
          'Download complete. The app will close and relaunch to install.',
          type: UiTextType.bodyMedium,
          color: colorScheme.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: Space.xl),
        UiButton(
          'Install now',
          icon: Icons.install_desktop_rounded,
          expand: true,
          onPressed: onChangePressed,
        ),
      ],
    );
  }
}

/// Primary action buttons: Update now / Check for updates (+ retry on error).
class _Actions extends StatelessWidget {
  final bool canUpdate;
  final bool failed;
  final VoidCallback onCheck;
  final VoidCallback onDownload;

  const _Actions({
    required this.canUpdate,
    required this.failed,
    required this.onCheck,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (canUpdate) {
      return UiButton(
        'Update now',
        icon: Icons.download_rounded,
        variant: UiButtonVariant.filled,
        expand: true,
        onPressed: onDownload,
      );
    }

    return Center(
      child: UiButton(
        failed ? 'Try again' : 'Check for updates',
        icon: Icons.refresh_rounded,
        variant: UiButtonVariant.outlined,
        foreground: colorScheme.primary,
        onPressed: onCheck,
      ),
    );
  }
}

/// Auto-check toggle shared with the settings entry for consistency.
class _AutoCheckToggle extends ConsumerWidget {
  const _AutoCheckToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoCheck = ref.watch(autoCheckUpdatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Rounded.xl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            Icons.autorenew_rounded,
            color: colorScheme.onSurfaceVariant,
            size: AppSizes.iconMd,
          ),
          SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UiText(
                  'Check automatically',
                  type: UiTextType.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
                UiText(
                  'Look for updates when the app starts',
                  type: UiTextType.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Switch(
            value: autoCheck,
            onChanged: (value) =>
                ref.read(autoCheckUpdatesProvider.notifier).setEnabled(value),
          ),
        ],
      ),
    );
  }
}

/// Shared outlined card shell for the info/changelog sections.
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const padding = Space.xl;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Rounded.x2l),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.iconLg * 1.4,
                height: AppSizes.iconLg * 1.4,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(Rounded.xl),
                ),
                child: Icon(icon, size: AppSizes.iconMd, color: colorScheme.onSecondaryContainer),
              ),
              SizedBox(width: Space.lg),
              UiText(
                title,
                type: UiTextType.titleMedium,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          SizedBox(height: Space.lg),
          ...children,
        ],
      ),
    );
  }
}

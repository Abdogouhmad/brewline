/// Riverpod state for the OTA update flow:
/// `idle / checking / available / downloading(progress) / readyToInstall / error`
///
/// The UI (settings section, action sheet, required screen) only talks to this
/// provider, which internally talks to the platform-appropriate
/// [UpdateInstaller] via [UpdateService]. This keeps every screen
/// platform-agnostic — the same shell renders on Android, Windows and Linux.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:brewline/core/updates/update_installer.dart';
import 'package:brewline/core/updates/update_manifest.dart';
import 'package:brewline/core/updates/update_service.dart';

/// SharedPreferences keys for the update settings.
const String kAutoCheckUpdatesKey = 'auto_check_updates';
const String kLastUpdateCheckKey = 'last_update_check_ms';
const String kUsePreReleasesKey = 'use_pre_releases';

/// Whether the app auto-checks for updates in the background on launch and on
/// entering the admin/waiter home. Defaults to `true` — a POS should surface
/// updates without the admin having to remember to look.
final autoCheckUpdatesProvider =
    NotifierProvider<AutoCheckUpdatesNotifier, bool>(
      AutoCheckUpdatesNotifier.new,
    );

class AutoCheckUpdatesNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(kAutoCheckUpdatesKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kAutoCheckUpdatesKey, enabled);
  }
}

/// Timestamp of the last successful update check, for the "last checked"
/// label in the settings section. `null` when never checked.
final lastUpdateCheckProvider =
    NotifierProvider<LastUpdateCheckNotifier, DateTime?>(
      LastUpdateCheckNotifier.new,
    );

class LastUpdateCheckNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final ms = prefs.getInt(kLastUpdateCheckKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markChecked() async {
    final now = DateTime.now();
    state = now;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(kLastUpdateCheckKey, now.millisecondsSinceEpoch);
  }
}

/// Whether the user has opted into pre-release updates. When enabled, the
/// update checker queries the GitHub Releases API in addition to the static
/// manifest, so pre-release versions are surfaced as available updates.
final usePreReleasesProvider =
    NotifierProvider<UsePreReleasesNotifier, bool>(
      UsePreReleasesNotifier.new,
    );

class UsePreReleasesNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(kUsePreReleasesKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kUsePreReleasesKey, enabled);
  }
}

enum UpdateStatus { idle, checking, available, downloading, readyToInstall, error }

/// The update state surfaced to the UI.
class UpdateState {
  final UpdateStatus status;
  final UpdateManifest? manifest;
  final UpdateCheckResult? checkResult;

  /// Download progress 0.0–1.0 while [UpdateStatus.downloading].
  final double? progress;

  /// Optional user-facing error message while [UpdateStatus.error].
  final String? error;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.manifest,
    this.checkResult,
    this.progress,
    this.error,
  });

  bool get hasUpdate =>
      checkResult == UpdateCheckResult.updateAvailable ||
      checkResult == UpdateCheckResult.updateMandatory;

  bool get isMandatory => checkResult == UpdateCheckResult.updateMandatory;

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateManifest? manifest,
    UpdateCheckResult? checkResult,
    bool clearManifest = false,
    double? progress,
    bool clearProgress = false,
    String? error,
  }) {
    return UpdateState(
      status: status ?? this.status,
      manifest: clearManifest ? null : (manifest ?? this.manifest),
      checkResult: checkResult ?? this.checkResult,
      progress: clearProgress ? null : (progress ?? this.progress),
      error: error ?? this.error,
    );
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) => const UpdateService());

/// Current platform's update installer.
final updateInstallerProvider = Provider<UpdateInstaller>(
  (ref) => ref.read(updateServiceProvider).installerForCurrentPlatform(),
);

/// The single OTA update notifier driving the whole flow.
final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(UpdateNotifier.new);

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  /// Triggers an update check. Silent on failure (never blocks startup).
  Future<void> checkForUpdates() async {
    state = state.copyWith(status: UpdateStatus.checking, error: null);
    final appInfo = ref.read(appInfoProvider).value;
    if (appInfo == null) {
      state = state.copyWith(status: UpdateStatus.idle);
      return;
    }

    final checkPreReleases = ref.read(usePreReleasesProvider);
    final outcome = await ref.read(updateServiceProvider).check(
      currentInfo: appInfo,
      checkPreReleases: checkPreReleases,
    );
    if (outcome.result == UpdateCheckResult.checkFailed) {
      state = state.copyWith(
        status: UpdateStatus.idle,
        checkResult: UpdateCheckResult.checkFailed,
        clearManifest: true,
      );
      return;
    }
    state = state.copyWith(
      status: UpdateStatus.available,
      manifest: outcome.manifest,
      checkResult: outcome.result,
      clearProgress: true,
      error: null,
    );
    await ref.read(lastUpdateCheckProvider.notifier).markChecked();
  }

  /// Downloads and installs the update for the current platform.
  ///
  /// On Android the system package installer takes over mid-flow; on desktop
  /// the extracted archive is unpacked and the app relaunches — in both cases
  /// this method returns once the download completes and the install/relaunch
  /// handoff begins.
  Future<void> downloadAndInstall() async {
    final manifest = state.manifest;
    if (manifest == null) return;

    final installer = ref.read(updateInstallerProvider);

    // Resolve the download URL for the current platform.
    final url = _urlFor(manifest, installer);
    final sha = _shaFor(manifest, installer);
    if (url == null || sha == null) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: 'This build has no update manifest entry.',
      );
      return;
    }

    try {
      state = state.copyWith(status: UpdateStatus.downloading, progress: 0);
      await installer.download(
        url,
        sha,
        onProgress: (p) => state = state.copyWith(progress: p),
      );
      state = state.copyWith(status: UpdateStatus.readyToInstall, progress: 1);
      await installer.install();
      state = state.copyWith(status: UpdateStatus.idle, clearManifest: true);
    } on UpdateIntegrityException catch (e) {
      state = state.copyWith(status: UpdateStatus.error, error: e.message);
    } on UpdateInstallException catch (e) {
      state = state.copyWith(status: UpdateStatus.error, error: e.message);
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: 'Download failed: $e',
      );
    }
  }

  String? _urlFor(UpdateManifest manifest, UpdateInstaller installer) {
    if (Platform.isAndroid) return manifest.android?.apkUrl;
    if (Platform.isWindows) return manifest.windows?.archiveUrl;
    if (Platform.isLinux) return manifest.linux?.archiveUrl;
    return null;
  }

  String? _shaFor(UpdateManifest manifest, UpdateInstaller installer) {
    if (Platform.isAndroid) return manifest.android?.sha256;
    if (Platform.isWindows) return manifest.windows?.sha256;
    if (Platform.isLinux) return manifest.linux?.sha256;
    return null;
  }
}

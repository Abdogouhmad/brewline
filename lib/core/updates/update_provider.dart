/// Riverpod state for the OTA update flow:
/// `idle / checking / available / downloading(progress) / readyToInstall / error`
///
/// The UI (settings section, action sheet, required screen) only talks to this
/// provider, which internally talks to the platform-appropriate
/// [UpdateInstaller] via [UpdateService]. This keeps every screen
/// platform-agnostic — the same shell renders on Android, Windows and Linux.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:brewline/core/updates/github_release.dart';
import 'package:brewline/core/updates/update_installer.dart';
import 'package:brewline/core/updates/update_notifications.dart';
import 'package:brewline/core/updates/update_service.dart';

/// SharedPreferences keys for the update settings.
const String kAutoCheckUpdatesKey = 'auto_check_updates';
const String kLastUpdateCheckKey = 'last_update_check_ms';

/// SharedPreferences key holding the version of the update we already showed a
/// notification for, so a new version isn't re-announced on every launch.
const String kLastUpdateNotifiedKey = 'last_update_notified_version';

/// Result of the most recent check (as `UpdateCheckResult.name`), so the admin
/// can distinguish "never checked" from "check failed" in the UI.
const String kLastUpdateCheckResultKey = 'last_update_check_result';

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

/// Timestamp of the last update check (successful or failed), for the "last
/// checked" label in the settings section. `null` when never checked.
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

  /// Records the timestamp for the check that just ran (whatever its outcome)
  /// alongside its [result], so the UI can show "Last checked: … · failed" vs
  /// "never checked".
  Future<void> markChecked(UpdateCheckResult result) async {
    final now = DateTime.now();
    state = now;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(kLastUpdateCheckKey, now.millisecondsSinceEpoch);
    await ref
        .read(lastUpdateCheckResultProvider.notifier)
        .markResult(result);
  }
}

/// Outcome of the most recent update check as persisted across launches.
/// `null` means the app has never completed a check.
final lastUpdateCheckResultProvider = NotifierProvider<
  LastUpdateCheckResultNotifier,
  UpdateCheckResult?
>(LastUpdateCheckResultNotifier.new);

class LastUpdateCheckResultNotifier extends Notifier<UpdateCheckResult?> {
  @override
  UpdateCheckResult? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final name = prefs.getString(kLastUpdateCheckResultKey);
    if (name == null) return null;
    return UpdateCheckResult.values.asNameMap()[name];
  }

  Future<void> markResult(UpdateCheckResult result) async {
    state = result;
    await ref
        .read(sharedPreferencesProvider)
        .setString(kLastUpdateCheckResultKey, result.name);
  }
}

enum UpdateStatus { idle, checking, available, downloading, readyToInstall, error }

/// Failure kinds surfaced while [UpdateStatus.error]. The provider stores a
/// code (never a user-facing string — the UI maps it to localized copy).
enum UpdateErrorCode {
  /// No downloadable asset exists for the current platform.
  noBuild,

  /// The download itself failed (network / transport).
  downloadFailed,

  /// The downloaded archive failed checksum verification.
  integrity,

  /// The unpack/install step threw.
  install,
}

/// The update state surfaced to the UI.
class UpdateState {
  final UpdateStatus status;

  /// The latest release found by the last check (original + updated release).
  final GitHubRelease? release;

  /// The release asset this device should download.
  final UpdateAsset? asset;
  final UpdateCheckResult? checkResult;

  /// Download progress 0.0–1.0 while [UpdateStatus.downloading].
  final double? progress;

  /// Optional failure kind while [UpdateStatus.error]; the UI maps each code
  /// to localized copy (improve.md §4 — no raw strings in the provider layer).
  final UpdateErrorCode? error;

  /// Optional diagnostic detail (e.g. a platform error message) shown below
  /// the localized [error] text. Never the primary copy.
  final String? errorDetail;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.release,
    this.asset,
    this.checkResult,
    this.progress,
    this.error,
    this.errorDetail,
  });

  bool get hasUpdate =>
      checkResult == UpdateCheckResult.updateAvailable ||
      checkResult == UpdateCheckResult.updateMandatory;

  bool get isMandatory => checkResult == UpdateCheckResult.updateMandatory;

  UpdateState copyWith({
    UpdateStatus? status,
    GitHubRelease? release,
    UpdateAsset? asset,
    UpdateCheckResult? checkResult,
    bool clearRelease = false,
    bool clearAsset = false,
    double? progress,
    bool clearProgress = false,
    UpdateErrorCode? error,
    String? errorDetail,
    bool clearError = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      release: clearRelease ? null : (release ?? this.release),
      asset: clearAsset ? null : (asset ?? this.asset),
      checkResult: checkResult ?? this.checkResult,
      progress: clearProgress ? null : (progress ?? this.progress),
      error: clearError ? null : (error ?? this.error),
      errorDetail: clearError ? null : errorDetail ?? this.errorDetail,
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
    // `PackageInfo` resolves asynchronously (platform channel). Await the
    // future instead of reading `.value`, which is null until it resolves —
    // otherwise the early startup auto-check would silently abort before the
    // installed version is ever known, and OTA detection would do nothing.
    AppInfoData? appInfo;
    try {
      appInfo = await ref.read(appInfoProvider.future);
    } catch (_) {
      appInfo = null;
    }
    if (appInfo == null) {
      state = state.copyWith(status: UpdateStatus.idle);
      return;
    }

    final outcome = await ref.read(updateServiceProvider).check(
      currentInfo: appInfo,
    );
    if (outcome.result == UpdateCheckResult.checkFailed) {
      // A failed check is still a check: persist the timestamp + "failed"
      // result so the admin can tell "check failed" from "never checked".
      await ref.read(lastUpdateCheckProvider.notifier).markChecked(
        UpdateCheckResult.checkFailed,
      );
      state = state.copyWith(
        status: UpdateStatus.idle,
        checkResult: UpdateCheckResult.checkFailed,
        clearRelease: true,
        clearAsset: true,
      );
      return;
    }
    state = state.copyWith(
      status: UpdateStatus.available,
      release: outcome.release,
      asset: outcome.asset,
      checkResult: outcome.result,
      clearProgress: true,
      error: null,
    );
    await ref
        .read(lastUpdateCheckProvider.notifier)
        .markChecked(outcome.result);
    await _notifyIfNew(outcome);
  }

  /// Shown once per release: fires the local notification the first time this
  /// device discovers [outcome]'s update. The in-app banner/section always
  /// shows the update; the notification is the passive nudge for when the
  /// admin isn't looking at the settings tab (e.g. on the login screen or
  /// waiter dashboard). Fires for both optional and mandatory updates — the
  /// mandatory take-over screen is layered on top regardless.
  Future<void> _notifyIfNew(UpdateCheckOutcome outcome) async {
    final notifications = ref.read(updateNotificationsProvider);
    final release = outcome.release;
    if (notifications == null || !outcome.hasUpdate || release == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getString(kLastUpdateNotifiedKey) == release.version) return;

    await notifications.notifyUpdate(
      version: release.version,
      releaseNotes: release.releaseNotes,
    );
    await prefs.setString(kLastUpdateNotifiedKey, release.version);
  }

  /// Downloads and installs the update for the current platform.
  ///
  /// On Android the system package installer takes over mid-flow; on desktop
  /// the extracted archive is unpacked and the app relaunches — in both cases
  /// this method returns once the download completes and the install/relaunch
  /// handoff begins.
  Future<void> downloadAndInstall() async {
    final asset = state.asset;
    if (asset == null) return;

    final installer = ref.read(updateInstallerProvider);

    if (asset.downloadUrl.isEmpty) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.noBuild,
      );
      return;
    }

    try {
      state = state.copyWith(status: UpdateStatus.downloading, progress: 0);
      await installer.download(
        asset.downloadUrl,
        expectedSha256: asset.sha256,
        onProgress: (p) => state = state.copyWith(progress: p),
      );
      state = state.copyWith(status: UpdateStatus.readyToInstall, progress: 1);
      await installer.install();
      state = state.copyWith(
        status: UpdateStatus.idle,
        clearRelease: true,
        clearAsset: true,
      );
    } on UpdateIntegrityException catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.integrity,
        errorDetail: e.message,
      );
    } on UpdateInstallException catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.install,
        errorDetail: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        error: UpdateErrorCode.downloadFailed,
        errorDetail: e.toString(),
      );
    }
  }
}

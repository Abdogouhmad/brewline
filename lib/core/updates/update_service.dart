/// Fetches the latest published GitHub release, picks the asset matching the
/// current platform, and compares it against the installed version.
///
/// This replaces the old static `update_manifest.json` approach: there is now a
/// single source of truth — the GitHub **release itself**. The app calls the
/// Releases API (`releases/latest`), which serves the newest non-prerelease
/// tag, its assets (APKs / archives) and the release body (used verbatim as the
/// in-app changelog).
///
/// The one trade-off is GitHub's unauthenticated rate limit (60 req/h per IP);
/// a failed or offline check is always silent — it never blocks startup and
/// never surfaces as an error for a routine background check.
library;

import 'dart:io';

import 'package:dio/dio.dart';

import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/android_update_installer.dart';
import 'package:brewline/core/updates/desktop_update_installer.dart';
import 'package:brewline/core/updates/github_release.dart';
import 'package:brewline/core/updates/update_installer.dart';

/// Compile-time constant so the API base can't drift between the code and the
/// CI workflow that publishes the releases.
const String kGitHubRepo = 'Abdogouhmad/brewline';

/// The GitHub Releases API base for [kGitHubRepo].
const String kReleasesApiBase = 'https://api.github.com/repos/$kGitHubRepo';

class UpdateService {
  const UpdateService();

  /// Fetches the newest release from GitHub. Returns `null` on any failure
  /// (offline, rate-limited, 404, bad JSON) so callers can treat a failed
  /// background check as "check again later".
  Future<GitHubRelease?> fetchLatestRelease() async {
    try {
      final dio = Dio();
      final response = await dio.get<Map<String, dynamic>>(
        '$kReleasesApiBase/releases/latest',
        options: Options(
          responseType: ResponseType.json,
          headers: {HttpHeaders.userAgentHeader: 'brewline/$kGitHubRepo'},
        ),
      );
      return GitHubRelease.fromJson(response.data ?? const {});
    } on DioException {
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Resolves the [UpdateInstaller] for the current platform.
  UpdateInstaller installerForCurrentPlatform() {
    if (Platform.isAndroid) return AndroidUpdateInstaller();
    if (Platform.isWindows || Platform.isLinux) {
      return DesktopUpdateInstaller();
    }
    throw UnsupportedError(
      'OTA updates are not supported on ${Platform.operatingSystem}',
    );
  }

  /// Performs a full update check: fetch the latest release, choose the
  /// platform installer, and compare versions.
  ///
  /// Returns the release and its matching asset on success (for consumers that
  /// need the release notes / download URL) or `null`s when the check failed.
  Future<UpdateCheckOutcome> check({
    required AppInfoData currentInfo,
  }) async {
    final release = await fetchLatestRelease();
    if (release == null) {
      return const UpdateCheckOutcome(null, null, UpdateCheckResult.checkFailed);
    }
    final asset = await release.pickAssetForCurrentPlatform();
    if (asset == null) {
      // The release exists but has nothing this device can install.
      return const UpdateCheckOutcome(null, null, UpdateCheckResult.checkFailed);
    }
    try {
      final result = installerForCurrentPlatform().checkForUpdate(
        release,
        currentInfo,
      );
      return UpdateCheckOutcome(release, asset, result);
    } on UnsupportedError {
      // macOS/iOS have no OTA installer — treat as "nothing to check"
      // rather than letting the caller crash on an unsupported platform.
      return const UpdateCheckOutcome(null, null, UpdateCheckResult.checkFailed);
    }
  }
}

/// Result of a version check, wrapping the release + matching platform asset
/// (if fetched) with the comparison result.
class UpdateCheckOutcome {
  final GitHubRelease? release;
  final UpdateAsset? asset;
  final UpdateCheckResult result;

  const UpdateCheckOutcome(this.release, this.asset, this.result);

  bool get hasUpdate =>
      result == UpdateCheckResult.updateAvailable ||
      result == UpdateCheckResult.updateMandatory;
}
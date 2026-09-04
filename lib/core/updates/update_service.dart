/// Fetches the OTA update manifest, picks the right platform section, and
/// compares against the installed version.
///
/// The manifest is a static JSON file hosted free on GitHub raw — the app
/// never calls GitHub's Releases API (which excludes pre-releases by design
/// and is rate-limited to 60 req/h per unauth'd IP). A failed or offline check
/// is always silent — it never blocks startup and never surfaces as an error
/// for a routine background check.
///
/// The manifest URL is selected from the build's [kUpdateChannel], keeping the
/// `beta` (pre-release) and `stable` manifests as two separate files so a
/// production device can never accidentally pull a beta build just because a
/// config value got flipped.
library;

import 'dart:io';

import 'package:dio/dio.dart';

import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/android_update_installer.dart';
import 'package:brewline/core/updates/desktop_update_installer.dart';
import 'package:brewline/core/updates/update_installer.dart';
import 'package:brewline/core/updates/update_manifest.dart';

/// Base path for the update manifests, hosted free on GitHub raw.
///
/// The `stable` channel reads `update_manifest.json` and the `beta` channel
/// reads `update_manifest_beta.json` — see [kUpdateChannel]. These are
/// compile-time constants so they can't drift from the CI workflow that writes
/// to the same paths.
const String kUpdateManifestBaseUrl =
    'https://raw.githubusercontent.com/Abdogouhmad/brewline/main';

/// The manifest file for the build's [kUpdateChannel]. Beta lives in a
/// separate file so a production build reading the stable URL can never
/// stumble onto a pre-release.
String get kUpdateManifestUrl =>
    kUpdateChannel == UpdateChannel.beta
        ? '$kUpdateManifestBaseUrl/update_manifest_beta.json'
        : '$kUpdateManifestBaseUrl/update_manifest.json';

class UpdateService {
  const UpdateService();

  /// Downloads and parses the update manifest for the current channel, then
  /// verifies it actually belongs to that channel. Returns `null` on any
  /// failure (offline, 404, bad JSON, channel mismatch) so callers can treat a
  /// failed background check as "check again later".
  Future<UpdateManifest?> fetchManifest() async {
    try {
      final dio = Dio();
      final response = await dio.get<Map<String, dynamic>>(
        kUpdateManifestUrl,
        options: Options(
          responseType: ResponseType.json,
          headers: {HttpHeaders.userAgentHeader: 'brewline'},
        ),
      );
      final manifest = UpdateManifest.fromJson(response.data ?? const {});

      // A manifest published for a different channel than this build is
      // ignored entirely — a stable build never consumes a beta manifest, no
      // matter how its URL got resolved.
      if (manifest.channel != kUpdateChannel) return null;
      return manifest;
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

  /// Performs a full update check: fetch the channel manifest, choose the
  /// platform installer, and compare versions.
  ///
  /// Returns the manifest on success (for consumers that need the release
  /// notes / URLs) or `null` when the check failed.
  Future<UpdateCheckOutcome> check({
    required AppInfoData currentInfo,
  }) async {
    final manifest = await fetchManifest();
    if (manifest == null) {
      return const UpdateCheckOutcome(null, UpdateCheckResult.checkFailed);
    }
    final result = installerForCurrentPlatform()
        .checkForUpdate(manifest, currentInfo);
    return UpdateCheckOutcome(manifest, result);
  }
}

/// Result of a version check, wrapping the manifest (if fetched) with the
/// comparison result.
class UpdateCheckOutcome {
  final UpdateManifest? manifest;
  final UpdateCheckResult result;

  const UpdateCheckOutcome(this.manifest, this.result);

  bool get hasUpdate =>
      result == UpdateCheckResult.updateAvailable ||
      result == UpdateCheckResult.updateMandatory;
}

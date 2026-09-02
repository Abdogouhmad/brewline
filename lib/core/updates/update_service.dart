/// Fetches the OTA update manifest, picks the right platform section, and
/// compares against the installed version.
///
/// The manifest URL is hosted free on GitHub Releases (raw URL), following the
/// hosting strategy from `improve.md` §2. A failed or offline check is always
/// silent — it never blocks startup and never surfaces as an error for a
/// routine background check.
library;

import 'dart:io';

import 'package:dio/dio.dart';

import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/android_update_installer.dart';
import 'package:brewline/core/updates/desktop_update_installer.dart';
import 'package:brewline/core/updates/update_installer.dart';
import 'package:brewline/core/updates/update_manifest.dart';

/// Where the update manifest lives. The app's built-in version constant is
/// used as the raw GitHub path so the manifest URL needs no hardcoding beyond
/// the org/repo (see `UPDATE_MANIFEST_URL` below).
///
/// This is a compile-time constant so it can't drift out of sync with the
/// packaging that the CI workflow writes to the same path.
const String kUpdateManifestUrl =
    'https://raw.githubusercontent.com/Abdogouhmad/brewline/main/update.json';

class UpdateService {
  const UpdateService();

  /// Downloads and parses the update manifest, then picks the section for the
  /// current platform. Returns `null` on any failure (offline, 404, bad JSON)
  /// so callers can treat a failed background check as "check again later".
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
      return UpdateManifest.fromJson(response.data ?? const {});
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

  /// Performs a full update check: fetch manifest, choose the platform
  /// installer, and compare versions. Returns the manifest on success (for
  /// consumers that need the release notes / URLs) or `null` when the check
  /// failed but the caller still wants the manifest.
  Future<UpdateCheckOutcome> check({required AppInfoData currentInfo}) async {
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

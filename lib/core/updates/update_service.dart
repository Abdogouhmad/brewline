/// Fetches the OTA update manifest, picks the right platform section, and
/// compares against the installed version.
///
/// The manifest URL is hosted free on GitHub Releases (raw URL), following the
/// hosting strategy from `improve.md` §2. A failed or offline check is always
/// silent — it never blocks startup and never surfaces as an error for a
/// routine background check.
///
/// As a fallback, the service also queries the GitHub Releases API to detect
/// pre-release versions that may not yet be reflected in the static manifest.
/// This check is rate-limited to once per 6 hours to stay well within the
/// unauthenticated API limit (60 req/h).
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const String _kGitHubApiReleasesUrl =
    'https://api.github.com/repos/Abdogouhmad/brewline/releases/latest';

const String _kLastGitHubCheckKey = 'last_github_release_check_ms';
const Duration _kGitHubCheckInterval = Duration(hours: 6);

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

  /// Fetches the latest GitHub release (including pre-releases) and returns
  /// it as an [UpdateManifest] if it's newer than [manifest].
  ///
  /// Rate-limited to one call per [_kGitHubCheckInterval] to avoid hitting
  /// the unauthenticated GitHub API limit.
  Future<UpdateManifest?> _fetchLatestGitHubRelease(
    UpdateManifest? manifest,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckMs = prefs.getInt(_kLastGitHubCheckKey);
      if (lastCheckMs != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastCheckMs;
        if (elapsed < _kGitHubCheckInterval.inMilliseconds) {
          return null;
        }
      }

      final dio = Dio();
      final response = await dio.get<Map<String, dynamic>>(
        _kGitHubApiReleasesUrl,
        options: Options(
          responseType: ResponseType.json,
          headers: {
            HttpHeaders.userAgentHeader: 'brewline',
            'Accept': 'application/vnd.github.v3+json',
          },
        ),
      );

      await prefs.setInt(
        _kLastGitHubCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      final data = response.data;
      if (data == null) return null;

      return _buildManifestFromRelease(data, manifest);
    } on DioException {
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Builds an [UpdateManifest] from a GitHub release API response, but only
  /// if the release version is actually newer than what [manifest] advertises.
  UpdateManifest? _buildManifestFromRelease(
    Map<String, dynamic> release,
    UpdateManifest? manifest,
  ) {
    final tagName = release['tag_name'] as String?;
    if (tagName == null) return null;

    final version = tagName.replaceFirst(RegExp(r'^v'), '');
    final assets = release['assets'] as List<dynamic>? ?? [];
    final publishedAt = release['published_at'] as String?;

    if (Platform.isAndroid) {
      final currentCode = manifest?.android?.latestVersionCode ?? 0;
      final versionCode = _extractBuildNumber(version) ?? 0;
      if (versionCode <= currentCode) return null;

      final apkAsset = _findAsset(assets, '.apk');
      if (apkAsset == null) return null;

      return UpdateManifest(
        android: AndroidUpdateInfo(
          latestVersionCode: versionCode,
          latestVersionName: version,
          minSupportedVersionCode: manifest?.android?.minSupportedVersionCode ?? 1,
          mandatory: manifest?.android?.mandatory ?? false,
          apkUrl: apkAsset['browser_download_url'] as String,
          sha256: manifest?.android?.sha256 ?? '',
        ),
        windows: manifest?.windows,
        linux: manifest?.linux,
        releaseNotes: (release['body'] as String?) ?? manifest?.releaseNotes ?? '',
        publishedAt: publishedAt != null
            ? DateTime.parse(publishedAt)
            : manifest?.publishedAt ?? DateTime.now(),
      );
    }

    if (Platform.isWindows || Platform.isLinux) {
      final currentVersion = Platform.isWindows
          ? manifest?.windows?.latestVersion
          : manifest?.linux?.latestVersion;
      final latestVersion = _stripBuildMetadata(version);

      if (currentVersion != null) {
        try {
          final current = Version.parse(currentVersion);
          final latest = Version.parse(latestVersion);
          if (current >= latest) return null;
        } on FormatException {
          return null;
        }
      }

      final ext = Platform.isWindows ? '.zip' : '.tar.gz';
      final asset = _findAsset(assets, ext);
      if (asset == null) return null;

      final info = DesktopUpdateInfo(
        latestVersion: latestVersion,
        minSupportedVersion: manifest != null
            ? (Platform.isWindows
                ? manifest.windows?.minSupportedVersion
                : manifest.linux?.minSupportedVersion) ??
                '1.0.0'
            : '1.0.0',
        mandatory: manifest != null
            ? (Platform.isWindows
                ? manifest.windows?.mandatory
                : manifest.linux?.mandatory) ??
                false
            : false,
        archiveUrl: asset['browser_download_url'] as String,
        sha256: manifest != null
            ? (Platform.isWindows
                ? manifest.windows?.sha256
                : manifest.linux?.sha256) ??
                ''
            : '',
      );

      return UpdateManifest(
        android: manifest?.android,
        windows: Platform.isWindows ? info : manifest?.windows,
        linux: Platform.isLinux ? info : manifest?.linux,
        releaseNotes: (release['body'] as String?) ?? manifest?.releaseNotes ?? '',
        publishedAt: publishedAt != null
            ? DateTime.parse(publishedAt)
            : manifest?.publishedAt ?? DateTime.now(),
      );
    }

    return null;
  }

  /// Extracts the build number from a version string like `1.4.0+8`.
  int? _extractBuildNumber(String version) {
    final parts = version.split('+');
    if (parts.length < 2) return null;
    return int.tryParse(parts.last);
  }

  /// Strips build metadata (the `+N` suffix) for semver comparison.
  String _stripBuildMetadata(String version) {
    final idx = version.indexOf('+');
    return idx >= 0 ? version.substring(0, idx) : version;
  }

  /// Finds the first release asset whose name ends with [suffix].
  Map<String, dynamic>? _findAsset(List<dynamic> assets, String suffix) {
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith(suffix)) {
        return asset as Map<String, dynamic>;
      }
    }
    return null;
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
  /// installer, and compare versions. When [checkPreReleases] is `true`,
  /// also queries GitHub Releases for newer pre-release versions that may
  /// not be in the manifest yet.
  ///
  /// Returns the manifest on success (for consumers that need the release
  /// notes / URLs) or `null` when the check failed.
  Future<UpdateCheckOutcome> check({
    required AppInfoData currentInfo,
    bool checkPreReleases = false,
  }) async {
    var manifest = await fetchManifest();
    if (checkPreReleases) {
      final githubManifest = await _fetchLatestGitHubRelease(manifest);
      if (githubManifest != null) {
        manifest = githubManifest;
      }
    }

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

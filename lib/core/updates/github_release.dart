/// The OTA update source: the **latest GitHub release** of this repository.
///
/// Previously the app fetched a static, hand-maintained `update_manifest.json`
/// committed to `main` (one per channel, with per-platform checksums). That
/// file is gone — BrewLine now asks the GitHub Releases API for the latest
/// release directly and picks the asset matching the current platform:
///
/// - **Android** → the per-ABI split APK (`app-arm64-v8a-release.apk`,
///   `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`), falling back to
///   the universal `app-release.apk` when the CPU can't be identified.
/// - **Windows** → `brewline-windows-x64.zip`
/// - **Linux** → `brewline-linux-x64.tar.gz`
///
/// The release's body is itself the release notes, so there is exactly one
/// source of truth (the GitHub release) instead of a dedicated manifest that
/// could drift out of sync. GitHub exposes each asset's SHA-256 via its
/// `digest` field, which the installers verify before touching the installer.
library;

import 'dart:io';

/// One platform/architecture build attached to a GitHub release.
class UpdateAsset {
  /// Asset file name, e.g. `app-arm64-v8a-release.apk`.
  final String name;

  /// Direct download URL (`browser_download_url`), served by GitHub's CDN.
  final String downloadUrl;

  /// Asset size in bytes; `null` when GitHub didn't report it.
  final int? sizeBytes;

  /// SHA-256 of the asset (GitHub's `digest` field, without the `sha256:`
  /// prefix). `null` when the API didn't return one.
  final String? sha256;

  const UpdateAsset({
    required this.name,
    required this.downloadUrl,
    this.sizeBytes,
    this.sha256,
  });

  factory UpdateAsset.fromJson(Map<String, dynamic> json) {
    final digest = json['digest'] as String?;
    return UpdateAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      sizeBytes: json['size'] as int?,
      sha256: digest != null && digest.startsWith('sha256:')
          ? digest.substring('sha256:'.length)
          : null,
    );
  }
}

/// A released version of BrewLine, parsed from the GitHub Releases API.
///
/// The version is derived from the git tag (a leading `v` is stripped), so the
/// tag is the single source of truth for "how new is this". The Android
/// checker compares it against the installed `versionName` (which carries no
/// build number), sidestepping the per-ABI versionCode offset problem
/// entirely.
class GitHubRelease {
  /// Version string without the leading `v` (e.g. tag `1.5.0` → `1.5.0`).
  final String version;

  /// The release body — rendered as the in-app "What's new" changelog.
  final String releaseNotes;

  final DateTime publishedAt;

  final List<UpdateAsset> assets;

  const GitHubRelease({
    required this.version,
    required this.releaseNotes,
    required this.publishedAt,
    this.assets = const [],
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    return GitHubRelease(
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      releaseNotes: json['body'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      assets: [
        for (final asset in json['assets'] as List? ?? [])
          UpdateAsset.fromJson(Map<String, dynamic>.from(asset as Map)),
      ],
    );
  }

  /// Returns the asset with the given file [name], or `null` if this release
  /// doesn't carry it.
  UpdateAsset? assetForName(String name) {
    for (final asset in assets) {
      if (asset.name == name) return asset;
    }
    return null;
  }

  /// The asset this device should download, or `null` when this release has
  /// nothing installable on the current platform.
  Future<UpdateAsset?> pickAssetForCurrentPlatform() async {
    if (Platform.isAndroid) {
      final abi = await _cachedAndroidAbi();
      final preferred = switch (abi) {
        AndroidAbi.arm64V8a => 'app-arm64-v8a-release.apk',
        AndroidAbi.armeabiV7a => 'app-armeabi-v7a-release.apk',
        AndroidAbi.x8664 => 'app-x86_64-release.apk',
        AndroidAbi.unknown => null,
      };
      return assetForName(preferred ?? 'app-release.apk');
    }
    if (Platform.isWindows) {
      return assetForName('brewline-windows-x64.zip');
    }
    if (Platform.isLinux) {
      return assetForName('brewline-linux-x64.tar.gz');
    }
    return null;
  }
}

/// The Android CPU architecture this device runs on — used to pick the matching
/// per-ABI split APK so phones get the smallest possible download.
enum AndroidAbi { arm64V8a, armeabiV7a, x8664, unknown }

/// Memoised ABI probe. Spawning a process via `uname` is cheap, but the CPU
/// architecture never changes during a process' lifetime, so the result is
/// resolved once and re-used for every subsequent update check in this run.
Future<AndroidAbi>? _abiCache;

/// Detects the ABI by asking the kernel (`uname -m`), which is available on
/// Android. Falls back to [AndroidAbi.unknown] (universal APK) on any failure.
Future<AndroidAbi> _detectAndroidAbi() async {
  try {
    final result = await Process.run('uname', ['-m']);
    if (result.exitCode != 0) return AndroidAbi.unknown;
    final arch = (result.stdout as String).trim().toLowerCase();
    if (arch == 'aarch64' || arch == 'arm64') return AndroidAbi.arm64V8a;
    if (arch.startsWith('arm')) return AndroidAbi.armeabiV7a;
    if (arch == 'x86_64' || arch == 'amd64') return AndroidAbi.x8664;
    return AndroidAbi.unknown;
  } catch (_) {
    return AndroidAbi.unknown;
  }
}

/// Returns the cached ABI probe, resolving it on first use.
Future<AndroidAbi> _cachedAndroidAbi() =>
    _abiCache ??= _detectAndroidAbi();
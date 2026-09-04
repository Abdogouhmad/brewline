/// The update channel a build is pinned to. This is decided at **build time**
/// (a compile-time constant / build flavor) — never toggleable from the
/// Settings UI, so café staff can't accidentally pull a beta build onto a
/// production device.
///
/// - [UpdateChannel.stable]: only real, finished releases. Every café
///   production device should be pinned here.
/// - [UpdateChannel.beta]: includes pre-release/test builds, for the
///   developer's own testing devices only.
enum UpdateChannel {
  stable,
  beta;

  static UpdateChannel fromName(String? name) =>
      name == 'beta' ? UpdateChannel.beta : UpdateChannel.stable;
}

/// The compile-time channel this build is pinned to.
///
/// Change this to [UpdateChannel.beta] on a testing build itself, or drive it
/// from a Dart define (`--dart-define=UPDATE_CHANNEL=beta`) — do **not** expose
/// it through the Settings UI. The manifest URL (see `update_service.dart`)
/// reads this to fetch `update_manifest.json` vs `update_manifest_beta.json`.
const UpdateChannel kUpdateChannel = UpdateChannel.stable;

/// The multi-platform OTA update manifest — one JSON file, one hosting
/// location, with a section per platform. The app only ever reads the section
/// matching the device it's running on.
///
/// Example manifest:
/// ```json
/// {
///   "channel": "stable",
///   "android": { "latestVersionCode": 14, ... },
///   "windows": { "latestVersion": "1.4.0", ... },
///   "linux":   { "latestVersion": "1.4.0", ... },
///   "releaseNotes": "Added refund system",
///   "publishedAt": "2026-09-01T00:00:00Z"
/// }
/// ```
class UpdateManifest {
  /// Which channel this manifest was published for. The checker verifies it
  /// matches [kUpdateChannel] so a production build can never pick up a beta
  /// manifest even if one is reachable at a guessable URL.
  final UpdateChannel channel;
  final AndroidUpdateInfo? android;
  final DesktopUpdateInfo? windows;
  final DesktopUpdateInfo? linux;
  final String releaseNotes;
  final DateTime publishedAt;

  const UpdateManifest({
    this.channel = UpdateChannel.stable,
    this.android,
    this.windows,
    this.linux,
    required this.releaseNotes,
    required this.publishedAt,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      channel: UpdateChannel.fromName(json['channel'] as String?),
      android: json['android'] != null
          ? AndroidUpdateInfo.fromJson(
              Map<String, dynamic>.from(json['android'] as Map),
            )
          : null,
      windows: json['windows'] != null
          ? DesktopUpdateInfo.fromJson(
              Map<String, dynamic>.from(json['windows'] as Map),
            )
          : null,
      linux: json['linux'] != null
          ? DesktopUpdateInfo.fromJson(
              Map<String, dynamic>.from(json['linux'] as Map),
            )
          : null,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }
}

/// Android-specific update info. Uses integer [latestVersionCode] for
/// comparison (matches `PackageInfo.buildNumber`) and a human-readable
/// [latestVersionName].
class AndroidUpdateInfo {
  final int latestVersionCode;
  final String latestVersionName;
  final int minSupportedVersionCode;
  final bool mandatory;
  final String apkUrl;
  final String sha256;

  const AndroidUpdateInfo({
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.minSupportedVersionCode,
    required this.mandatory,
    required this.apkUrl,
    required this.sha256,
  });

  factory AndroidUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AndroidUpdateInfo(
      latestVersionCode: json['latestVersionCode'] as int,
      latestVersionName: json['latestVersionName'] as String,
      minSupportedVersionCode: json['minSupportedVersionCode'] as int,
      mandatory: json['mandatory'] as bool? ?? false,
      apkUrl: json['apkUrl'] as String,
      sha256: json['sha256'] as String,
    );
  }
}

/// Desktop (Windows / Linux) update info. Uses semantic version strings for
/// comparison via `pub_semver`.
class DesktopUpdateInfo {
  final String latestVersion;
  final String minSupportedVersion;
  final bool mandatory;
  final String archiveUrl;
  final String sha256;

  const DesktopUpdateInfo({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.mandatory,
    required this.archiveUrl,
    required this.sha256,
  });

  factory DesktopUpdateInfo.fromJson(Map<String, dynamic> json) {
    return DesktopUpdateInfo(
      latestVersion: json['latestVersion'] as String,
      minSupportedVersion: json['minSupportedVersion'] as String,
      mandatory: json['mandatory'] as bool? ?? false,
      archiveUrl: json['archiveUrl'] as String,
      sha256: json['sha256'] as String,
    );
  }
}

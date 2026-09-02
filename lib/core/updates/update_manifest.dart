/// The multi-platform OTA update manifest — one JSON file, one hosting
/// location, with a section per platform. The app only ever reads the section
/// matching the device it's running on.
///
/// Example manifest:
/// ```json
/// {
///   "android": { "latestVersionCode": 14, ... },
///   "windows": { "latestVersion": "1.4.0", ... },
///   "linux":   { "latestVersion": "1.4.0", ... },
///   "releaseNotes": "Added refund system",
///   "publishedAt": "2026-09-01T00:00:00Z"
/// }
/// ```
class UpdateManifest {
  final AndroidUpdateInfo? android;
  final DesktopUpdateInfo? windows;
  final DesktopUpdateInfo? linux;
  final String releaseNotes;
  final DateTime publishedAt;

  const UpdateManifest({
    this.android,
    this.windows,
    this.linux,
    required this.releaseNotes,
    required this.publishedAt,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
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

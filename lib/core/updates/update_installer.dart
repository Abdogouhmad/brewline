/// Platform-handler abstraction for OTA update mechanics.
///
/// Follows the same "one interface, per-platform implementation" convention
/// as [PrinterTransport] (`core/printing/printer_transport.dart`): callers
/// only ever talk to [UpdateInstaller], never to platform-specific packages
/// directly. The runtime chooser in `update_service.dart` picks the right
/// implementation based on the current platform.
library;

import 'dart:io';

import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/android_update_installer.dart';
import 'package:brewline/core/updates/desktop_update_installer.dart';
import 'package:brewline/core/updates/update_manifest.dart';

/// Result of comparing the installed version against the manifest.
enum UpdateCheckResult {
  /// The app is already up to date.
  upToDate,

  /// An update is available but not mandatory.
  updateAvailable,

  /// An update is available and mandatory — the admin must install it.
  updateMandatory,

  /// The check failed (network error, bad manifest, etc.).
  checkFailed,
}

/// Progress callback for download operations.
typedef DownloadProgress = void Function(double progress);

/// Thrown when a downloaded artifact fails SHA-256 checksum verification —
/// the guard before anything is installed.
class UpdateIntegrityException implements Exception {
  final String message;
  const UpdateIntegrityException(this.message);
  @override
  String toString() => 'UpdateIntegrityException: $message';
}

/// Thrown when the platform's install/relaunch step fails after the artifact
/// passed verification.
class UpdateInstallException implements Exception {
  final String message;
  const UpdateInstallException(this.message);
  @override
  String toString() => 'UpdateInstallException: $message';
}

/// Abstract interface for downloading and installing updates.
///
/// Each platform provides its own implementation:
/// - [AndroidUpdateInstaller]: downloads APK, verifies checksum, hands off
///   to the system package installer.
/// - [DesktopUpdateInstaller]: downloads archive (zip / tar.gz), verifies
///   checksum, extracts to a fresh versioned directory, and relaunches.
abstract class UpdateInstaller {
  const UpdateInstaller();

  /// Returns the current platform's installer.
  factory UpdateInstaller.current() {
    if (Platform.isAndroid) return AndroidUpdateInstaller();
    if (Platform.isWindows || Platform.isLinux) {
      return DesktopUpdateInstaller();
    }
    throw UnsupportedError(
      'OTA updates are not supported on ${Platform.operatingSystem}',
    );
  }

  /// Compares [currentInfo] against the relevant section of [manifest]
  /// and returns whether an update is available.
  UpdateCheckResult checkForUpdate(
    UpdateManifest manifest,
    AppInfoData currentInfo,
  );

  /// Downloads the update artifact from [url], verifying its SHA-256 against
  /// [expectedSha256]. [onProgress] is called with a value in 0.0–1.0.
  Future<void> download(
    String url,
    String expectedSha256, {
    DownloadProgress? onProgress,
  });

  /// Installs the previously downloaded update.
  ///
  /// On Android this hands off to the system package installer.
  /// On desktop this extracts the archive and relaunches the app.
  Future<void> install();
}

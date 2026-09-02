/// Android OTA update installer.
///
/// Downloads the APK to a temp file, verifies its SHA-256 checksum, then
/// hands off to `android_package_installer` for the system-level install.
///
/// ⚠️ **Keystore risk**: every release APK must be signed with the same
/// stable release keystore forever. A mismatched signature forces Android
/// to uninstall before "updating," which wipes the local SQLite database.
library;

import 'dart:async';
import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/update_installer.dart';
import 'package:brewline/core/updates/update_manifest.dart';

class AndroidUpdateInstaller implements UpdateInstaller {
  AndroidUpdateInstaller();

  String? _downloadedApkPath;

  @override
  UpdateCheckResult checkForUpdate(
    UpdateManifest manifest,
    AppInfoData currentInfo,
  ) {
    final info = manifest.android;
    if (info == null) return UpdateCheckResult.checkFailed;

    final currentCode = int.tryParse(currentInfo.buildNumber) ?? 0;
    if (currentCode >= info.latestVersionCode) {
      return UpdateCheckResult.upToDate;
    }
    return info.mandatory
        ? UpdateCheckResult.updateMandatory
        : UpdateCheckResult.updateAvailable;
  }

  @override
  Future<void> download(
    String url,
    String expectedSha256, {
    DownloadProgress? onProgress,
  }) async {
    final dio = Dio();
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/brewline-update.apk';
    final file = File(filePath);

    // Download to a temp file first, tracking progress.
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    // Verify the SHA-256 checksum before letting anything near the installer.
    final digest = await _sha256OfFile(file);
    if (digest.toLowerCase() != expectedSha256.toLowerCase()) {
      await file.delete();
      throw UpdateIntegrityException(
        'SHA-256 mismatch: expected $expectedSha256, got $digest',
      );
    }

    _downloadedApkPath = filePath;
  }

  @override
  Future<void> install() async {
    final path = _downloadedApkPath;
    if (path == null) {
      throw StateError('No APK downloaded — call download() first');
    }

    final result = await AndroidPackageInstaller.installApk(
      apkFilePath: path,
    );
    if (result != null && result != 1) {
      throw UpdateInstallException('Package installer returned code $result');
    }
    _downloadedApkPath = null;
  }

  /// Hashes a file in a streaming manner so a large APK never needs to be
  /// fully resident in memory.
  static Future<String> _sha256OfFile(File file) async {
    final sink = _DigestAccumulator();
    final hasher = sha256.startChunkedConversion(sink);
    await for (final chunk in file.openRead()) {
      hasher.add(chunk);
    }
    hasher.close();
    sink.close();
    return sink.digest;
  }
}

/// Minimal accumulator that captures the single [Digest] produced by a hash's
/// chunked conversion, since `DigestSink` isn't part of `crypto`'s public API.
class _DigestAccumulator implements Sink<Digest> {
  String digest = '';
  bool _set = false;

  @override
  void add(Digest data) {
    _set = true;
    digest = data.toString();
  }

  @override
  void close() {
    if (!_set) {
      throw StateError('DigestSink.add must be called before close');
    }
  }
}
/// Desktop (Windows + Linux) OTA update installer.
///
/// Downloads the platform archive (`.zip` on Windows, `.tar.gz` on Linux),
/// verifies its SHA-256 checksum, and extracts to a fresh, versioned
/// directory alongside the current install — **never overwriting in place**.
///
/// **Why never overwrite in place** (§4.2 step 3 of the improve spec): a
/// partially-overwritten running app is a much worse failure mode than a
/// failed download. If we tried to unpack the new version on top of the files
/// the current process is executing from, some files could be locked (Windows)
/// or replaced mid-run (Linux), leaving the app in a corrupt state we can't
/// recover from. Extracting to a sibling directory means the running app is
/// never touched; the only switch point is the relaunch, which atomically
/// points at the new versioned directory.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/updates/update_installer.dart';
import 'package:brewline/core/updates/update_manifest.dart';

class DesktopUpdateInstaller implements UpdateInstaller {
  DesktopUpdateInstaller();

  File? _downloadedArchive;

  @override
  UpdateCheckResult checkForUpdate(
    UpdateManifest manifest,
    AppInfoData currentInfo,
  ) {
    if (!Platform.isWindows && !Platform.isLinux) {
      return UpdateCheckResult.checkFailed;
    }
    final info = Platform.isWindows ? manifest.windows : manifest.linux;
    if (info == null) return UpdateCheckResult.checkFailed;

    try {
      final current = Version.parse(currentInfo.version);
      final latest = Version.parse(info.latestVersion);
      if (current >= latest) return UpdateCheckResult.upToDate;
      return info.mandatory
          ? UpdateCheckResult.updateMandatory
          : UpdateCheckResult.updateAvailable;
    } on FormatException {
      return UpdateCheckResult.checkFailed;
    }
  }

  @override
  Future<void> download(
    String url,
    String expectedSha256, {
    DownloadProgress? onProgress,
  }) async {
    final dio = Dio();
    final dir = await getTemporaryDirectory();
    final ext = Platform.isWindows ? '.zip' : '.tar.gz';
    final filePath = '${dir.path}/brewline-update$ext';
    final file = File(filePath);

    // Download to a temp file first, tracking progress.
    await dio.download(url, filePath, onReceiveProgress: (received, total) {
      if (total > 0 && onProgress != null) {
        onProgress(received / total);
      }
    });

    // Verify the SHA-256 checksum before admitting the archive.
    final digest = await _sha256OfFile(file);
    if (digest.toLowerCase() != expectedSha256.toLowerCase()) {
      await file.delete();
      throw UpdateIntegrityException(
        'SHA-256 mismatch: expected $expectedSha256, got $digest',
      );
    }

    _downloadedArchive = file;
  }

  @override
  Future<void> install() async {
    final archiveFile = _downloadedArchive;
    if (archiveFile == null) {
      throw StateError('No archive downloaded — call download() first');
    }

    final documents = await getApplicationDocumentsDirectory();

    // Fresh versioned directory alongside the running app's own directory.
    // Use a timestamp suffix so repeated installs of the "same" version never
    // collide on an existing directory.
    final versionDir = p.join(
      documents.path,
      'updates',
      Platform.isWindows ? 'windows' : 'linux',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
    Directory(versionDir).createSync(recursive: true);

    // Extract the archive (bytes already local) into the fresh directory.
    final bytes = archiveFile.readAsBytesSync();
    if (Platform.isWindows) {
      _extractZip(bytes, versionDir);
    } else {
      _extractTarGz(bytes, versionDir);
    }

    // Restore the executable bit on Linux (a silent, easy-to-miss failure
    // mode — a tarball doesn't always preserve it).
    if (Platform.isLinux) {
      _restoreExecutableBit(versionDir);
    }

    // Repoint the stable `current` symlink so any launcher / `.desktop`
    // shortcut keeps resolving to a fixed path after the update.
    _relaunchPlumbing(versionDir);

    archiveFile.deleteSync();
    _downloadedArchive = null;

    // Spawn the new executable and exit the current process.
    final exe = _executablePath(versionDir);
    if (!File(exe).existsSync()) {
      throw UpdateInstallException('New executable not found at $exe');
    }
    await Process.start(exe, [], mode: ProcessStartMode.detached);
    exit(0);
  }

  /// Executable entrypoint inside the versioned directory.
  String _executablePath(String versionDir) {
    const appName = 'brewline';
    if (Platform.isWindows) {
      return p.join(versionDir, '$appName.exe');
    }
    return p.join(versionDir, appName);
  }

  void _extractZip(Uint8List bytes, String destDir) {
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final outPath = p.join(destDir, file.name);
      if (file.isFile) {
        File(outPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }
  }

  void _extractTarGz(Uint8List bytes, String destDir) {
    final archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    for (final file in archive) {
      final outPath = p.join(destDir, file.name);
      if (file.isFile) {
        File(outPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
      } else {
        Directory(outPath).createSync(recursive: true);
      }
    }
  }

  void _restoreExecutableBit(String versionDir) {
    final exe = File(p.join(versionDir, 'brewline'));
    if (exe.existsSync()) {
      Process.runSync('chmod', ['+x', exe.path]);
    }
    // Shared objects under lib/ need their execute bits too for the dynamic
    // loader to reach them.
    final libDir = Directory(p.join(versionDir, 'lib'));
    if (libDir.existsSync()) {
      libDir.listSync(recursive: true).whereType<File>().forEach((f) {
        if (f.path.endsWith('.so')) {
          Process.runSync('chmod', ['+x', f.path]);
        }
      });
    }
  }

  /// Re-points the stable `current` symlink (used by the launch shortcut) at
  /// the new versioned directory, and prunes older versioned directories
  /// keeping only the last one as a rollback fallback.
  void _relaunchPlumbing(String versionDir) {
    final updatesRoot = p.dirname(versionDir);
    final currentLink = p.join(updatesRoot, 'current');

    // Remove any stale symlink (checks by filesystem type, since `Link` can
    // report existence even for a dangling target).
    if (FileSystemEntity.typeSync(currentLink, followLinks: false) ==
        FileSystemEntityType.link) {
      Link(currentLink).deleteSync();
    } else if (Directory(currentLink).existsSync()) {
      Directory(currentLink).deleteSync(recursive: true);
    } else if (File(currentLink).existsSync()) {
      File(currentLink).deleteSync();
    }
    Link(currentLink).createSync(p.basename(versionDir));

    // Prune old directories, keeping only the one we just made (the rollback
    // fallback) and removing everything before it.
    final dirs = Directory(updatesRoot)
        .listSync()
        .whereType<Directory>()
        .where((d) {
          if (p.basename(d.path) == 'current') return false;
          return FileSystemEntity.typeSync(d.path, followLinks: false) !=
              FileSystemEntityType.link;
        })
        .map((d) => d.path)
        .toList()
      ..sort();
    while (dirs.length > 1) {
      final old = dirs.removeAt(0);
      Directory(old).deleteSync(recursive: true);
    }
  }

  /// Hashes a file in a streaming manner so a large archive never needs to be
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
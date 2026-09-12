/// ZIP packing/unpacking and manifest read/write for `.brewline` backups.
///
/// A backup is a single ZIP archive (the project already depends on
/// `package:archive`) with a `.brewline` extension and this layout:
///
/// ```text
/// backup.brewline/
/// ├── manifest.json      # appVersion, schemaVersion, createdAt, deviceLabel
/// ├── brewline.db        # consistent VACUUM INTO snapshot of the live db
/// ├── preferences.json   # exported SharedPreferences (archival only — the
/// │                      #   restore step deliberately does NOT re-apply it,
/// │                      #   see backup_service.dart)
/// └── images/            # copied from the product image store
/// ```
///
/// The `schemaVersion` in the manifest is the single gate that decides whether
/// a restore is even attempted ([BackupService.validateManifest]) — everything
/// else in the archive is payload.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// File extension branding the backup archives.
const String kBackupExtension = 'brewline';

/// Thrown when a `.brewline` archive is unreadable, missing `manifest.json`,
/// or carries a manifest that cannot be parsed. Distinct from
/// [BackupSchemaTooNewException] — this is "not a valid backup", not "a valid
/// backup this app can't open yet".
class BackupCorruptArchiveException implements Exception {
  final String message;
  const BackupCorruptArchiveException(this.message);

  @override
  String toString() => 'BackupCorruptArchiveException: $message';
}

/// Header of a `.brewline` archive. [schemaVersion] is the strict restore
/// gate; [appVersion] is informational only (shown in the restore
/// confirmation so the admin has context before committing).
class BackupManifest {
  final String appVersion;

  /// Schema version of the database **inside** the archive.
  final int schemaVersion;

  final DateTime createdAt;

  /// Optional free-text device label ("Front Counter") that helps an admin
  /// with more than one backup file tell them apart. May be `null`.
  final String? deviceLabel;

  const BackupManifest({
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
    this.deviceLabel,
  });

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final createdAt = json['createdAt'];
    if (schemaVersion is! int || createdAt is! String) {
      throw const BackupCorruptArchiveException(
        'manifest.json is missing schemaVersion and/or createdAt',
      );
    }
    final version = json['appVersion'];
    final parsedCreatedAt = DateTime.tryParse(createdAt);
    if (parsedCreatedAt == null) {
      throw const BackupCorruptArchiveException(
        'manifest.json has an unparsable createdAt',
      );
    }
    return BackupManifest(
      appVersion: version is String ? version : 'unknown',
      schemaVersion: schemaVersion,
      createdAt: parsedCreatedAt,
      deviceLabel: json['deviceLabel'] is String
          ? (json['deviceLabel'] as String)
          : null,
    );
  }

  Map<String, Object> toJson() => {
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'deviceLabel': ?deviceLabel,
  };
}

/// Packs the contents of [sourceDirectory] into ZIP at [outputFile].
///
/// Entries are stored with paths relative to [sourceDirectory], so
/// `sourceDirectory/brewline.db` becomes `brewline.db` in the archive.
Future<File> writeBackupArchive({
  required Directory sourceDirectory,
  required File outputFile,
}) async {
  final archive = Archive();
  final walker = sourceDirectory.listSync(recursive: true);
  for (final entity in walker) {
    if (entity is! File) continue;
    final name = p.relative(entity.path, from: sourceDirectory.path);
    archive.addFile(
      ArchiveFile(name, entity.lengthSync(), entity.readAsBytesSync()),
    );
  }

  final bytes = ZipEncoder().encode(archive);
  if (bytes == null) {
    throw const BackupCorruptArchiveException('ZIP encoding failed');
  }
  await outputFile.writeAsBytes(bytes as Uint8List, flush: true);
  return outputFile;
}

/// Reads a packaged backup archive and returns its entries keyed by their
/// slash-separated archive path (e.g. `manifest.json`, `images/p-001.jpg`).
///
/// The whole archive is decoded in memory — at café scale (a SQLite db plus
/// a few hundred product thumbnails) this is comfortably small.
Map<String, Uint8List> readBackupArchive(File archiveFile) {
  final bytes = archiveFile.readAsBytesSync();
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes, verify: false);
  } on ArchiveException catch (e) {
    throw BackupCorruptArchiveException('Not a valid .brewline archive: $e');
  }
  final entries = <String, Uint8List>{};
  for (final file in archive) {
    if (file.isFile) {
      entries[file.name] = Uint8List.fromList(file.content as List<int>);
    }
  }
  if (entries.isEmpty) {
    throw const BackupCorruptArchiveException('Archive contains no files');
  }
  return entries;
}

/// Reads and parses `manifest.json` from [archiveFile] without extracting the
/// rest of the archive.
BackupManifest readManifest(File archiveFile) {
  final entries = readBackupArchive(archiveFile);
  final manifestBytes = entries['manifest.json'];
  if (manifestBytes == null) {
    throw const BackupCorruptArchiveException(
      'Archive has no manifest.json — not a brewline backup',
    );
  }
  final Map<String, dynamic> json;
  try {
    final decoded = jsonDecode(utf8.decode(manifestBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('manifest is not a JSON object');
    }
    json = decoded;
  } on FormatException catch (e) {
    throw BackupCorruptArchiveException('manifest.json is invalid JSON: $e');
  }
  return BackupManifest.fromJson(json);
}

/// Writes [manifest] as `manifest.json` inside [directory].
Future<void> writeManifest({
  required BackupManifest manifest,
  required Directory directory,
}) async {
  final file = File(p.join(directory.path, 'manifest.json'));
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
}
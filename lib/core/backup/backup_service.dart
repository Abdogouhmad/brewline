/// Backup & restore for the whole brewline database — the app has no server
/// or cloud sync, so the SQLite database on one tablet IS the business's sales
/// history, cashout records and audit trail. [BackupService] is the **only**
/// code that touches `VACUUM INTO` or swaps database files.
///
/// ## Why `VACUUM INTO`
///
/// A consistent snapshot is taken with `VACUUM INTO '<path>'` (SQLite ≥ 3.27).
/// It produces a compacted, self-consistent copy of the live database — the
/// whole schema, including every table added across every spec — **without
/// requiring exclusive access first**. It plugs directly on top of the
/// existing single [Database] connection this project relies on, so there is
/// no custom row-by-row export to keep in sync as the schema grows. Older
/// bundled SQLite (some Android devices) falls back to a WAL checkpoint +
/// plain file copy, which is the same single-writer view on this app's one
/// connection.
///
/// ## Why restore validates `schemaVersion` strictly
///
/// The manifest's `schemaVersion` is the single gate on restore:
///
/// * **newer than current** → rejected outright, before anything live is
///   touched. The app doesn't know the schema yet, so any "best-effort"
///   restore would be a partially-understood data swap.
/// * **older than current** → allowed. The restored `brewline.db` reopens at
///   its own (older) version and the normal `onUpgrade` migration chain runs
///   exactly as it would for any old install being upgraded.
/// * **equal** → straightforward restore.
///
/// Restore is the most destructive action in this app, so before any file is
/// swapped a **pre-restore safety snapshot** of the current database is written
/// to the `restore_snapshots/` directory with the same `VACUUM INTO` mechanism
/// as a normal backup. It is kept as an internal safety net (pruned to the
/// latest few) so a mistaken restore can always be undone.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:brewline/core/backup/backup_archive.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/repositories/audit_repository.dart';
import 'package:brewline/core/security/credential_store.dart';

/// Thrown when a backup was made with a newer app schema than the running app
/// understands, so a restore is **not** attempted. Carries a clear,
/// user-facing message ("update the app first").
class BackupSchemaTooNewException implements Exception {
  final int backupSchema;
  final int currentSchema;
  const BackupSchemaTooNewException({
    required this.backupSchema,
    required this.currentSchema,
  });

  @override
  String toString() => 'BackupSchemaTooNewException: '
      'backup schema $backupSchema > current schema $currentSchema';
}

/// Thrown when a restore fails after files started moving (close, snapshot and
/// validation succeeded). The pre-restore safety snapshot is left in place.
class BackupRestoreException implements Exception {
  final String message;
  const BackupRestoreException(this.message);

  @override
  String toString() => 'BackupRestoreException: $message';
}

/// SharedPreferences key for the device label shown in backup manifests.
const String kDeviceLabelKey = 'device_label';

/// Number of pre-restore safety snapshots kept in `restore_snapshots/`.
const int kPreRestoreSnapshotsToKeep = 5;

/// Upper bound on re-arming the platform keystore credential during a restore.
///
/// The credential write on Android goes through `flutter_secure_storage` — a
/// platform channel that has been observed to hang on some devices. Time-boxing
/// it means a stuck keystore can never wedge the restore permanently in its
/// progress dialog (see [_applyCredential]).
const Duration kCredentialWriteTimeout = Duration(seconds: 8);

/// Outcome of a successful [BackupService.restore]. The caller must restart
/// the app (fresh widget + provider tree) against the reopened database —
/// never keep hot-swapping a live connection under a running UI.
class BackupRestoreResult {
  final BackupManifest manifest;
  const BackupRestoreResult({required this.manifest});
}

class BackupService {
  /// The live connection used for `VACUUM INTO` snapshots and audit logging.
  final Database database;

  final SharedPreferences preferences;

  /// Installed app version — recorded in the manifest for the admin's context
  /// only; it is `schemaVersion`, not this, that gates a restore.
  final String appVersion;

  /// Database driver used to re-open the swapped file (plugin on Android/iOS,
  /// FFI elsewhere). Overridable in tests.
  final DatabaseFactory factory;

  /// Absolute path of the product-image store (`product_images/`).
  final Directory imagesDirectory;

  /// Directory holding pre-restore safety snapshots (`restore_snapshots/`).
  final Directory snapshotDirectory;

  /// Where the admin login credential lives (secure storage on mobile,
  /// SharedPreferences on desktop). When set, `create()` packs the credential
  /// into the archive and `restore()` re-arms it (plus the onboarding flag),
  /// so a restored install lands on the login screen ready for the restored
  /// admin PIN instead of the onboarding setup screen.
  final CredentialStore? credentialStore;

  BackupService({
    required this.database,
    required this.preferences,
    required this.appVersion,
    DatabaseFactory? factory,
    required this.imagesDirectory,
    required this.snapshotDirectory,
    this.credentialStore,
  }) : factory = factory ?? databaseFactoryForPlatform();

  /// Validates that [archiveFile] is a well-formed `.brewline` backup this
  /// app can restore. Returns the parsed [BackupManifest], or throws:
  ///
  /// * [BackupCorruptArchiveException] — not a valid backup (missing/broken
  ///   manifest, unreadable zip).
  /// * [BackupSchemaTooNewException] — a valid backup from a newer app.
  Future<BackupManifest> validateManifest(File archiveFile) async {
    final manifest = readManifest(archiveFile);
    final current = kDatabaseSchemaVersion;
    if (manifest.schemaVersion > current) {
      throw BackupSchemaTooNewException(
        backupSchema: manifest.schemaVersion,
        currentSchema: current,
      );
    }
    return manifest;
  }

  /// Creates a `.brewline` backup archive at [outputPath].
  ///
  /// 1. `VACUUM INTO` a compacted snapshot of the live database.
  /// 2. Export every SharedPreferences value to `preferences.json`.
  /// 3. Copy the product-image store into `images/`.
  /// 4. Write `manifest.json`.
  /// 5. Pack everything into one ZIP named [outputPath].
  ///
  /// The archive is first written to a temp file in the destination directory
  /// and renamed into place, so a failure mid-packing can't leave a
  /// half-written archive where the admin asked for one. On success a
  /// `backup_created` event is appended to the audit log.
  Future<File> create({
    required String outputPath,
    required String actor,
  }) async {
    final staging = await Directory.systemTemp.createTemp('brewline_backup_');
    final destinationDir = Directory(p.dirname(outputPath));
    await destinationDir.create(recursive: true);
    final packedTarget = File(
      p.join(destinationDir.path, '.brewline_pack_${DateTime.now().millisecondsSinceEpoch}'),
    );

    try {
      await _vacuumInto(File(p.join(staging.path, kBrewlineDatabaseName)));
      await _exportPreferences(staging);
      await _exportCredential(staging);
      await _copyImages(staging);
      await writeManifest(
        manifest: BackupManifest(
          appVersion: appVersion,
          schemaVersion: kDatabaseSchemaVersion,
          createdAt: DateTime.now(),
          deviceLabel: _deviceLabel(),
        ),
        directory: staging,
      );

      await writeBackupArchive(sourceDirectory: staging, outputFile: packedTarget);

      // Temp-then-rename: never leave a partial file at the admin's chosen
      // path. Same-filesystem rename fails cleanly if the user picked a
      // directory we can't write a temp into.
      try {
        await packedTarget.rename(outputPath);
      } on FileSystemException {
        await packedTarget.copy(outputPath);
        await packedTarget.delete();
      }

      await AuditRepository(database).logEvent(
        eventType: 'backup_created',
        actor: actor,
        metadata: jsonEncode({
          'schemaVersion': kDatabaseSchemaVersion,
          'file': p.basename(outputPath),
        }),
      );
      return File(outputPath);
    } finally {
      await staging.delete(recursive: true);
      if (await packedTarget.exists()) {
        await packedTarget.delete();
      }
    }
  }

  /// Restores [archiveFile] onto the live database owned by [dbHandle].
  ///
  /// Order matters (§4 of the spec — especially on Windows, which locks open
  /// files harder than Linux):
  ///
  /// 1. Validate the manifest first — reject a newer schema before touching
  ///    anything ([validateManifest]).
  /// 2. Write a **pre-restore safety snapshot** of the current database via the
  ///    same `VACUUM INTO` path as a normal backup, so a mistaken restore can
  ///    be undone.
  /// 3. Extract the archive's `brewline.db` + `images/` to a staging directory
  ///    created **next to** the database file (same filesystem ⇒ renames can't
  ///    fail with EXDEV).
  /// 4. Close every database connection ([AppDatabaseHandle.close]).
  /// 5. Swap files write-temp-then-rename — never a direct in-place overwrite,
  ///    so a mid-copy failure can't leave a half-written database where the
  ///    real one used to be.
  /// 6. Reopen the database; if the archive's db is at an older schema the
  ///    existing migration chain runs here automatically.
  /// 7. Append a `backup_restored` audit event **to the restored database**,
  ///    so the audit trail itself records that the data underneath it changed.
  ///
  /// Returns a [BackupRestoreResult]; the caller should then restart the app.
  Future<BackupRestoreResult> restore({
    required File archiveFile,
    required AppDatabaseHandle dbHandle,
    required String actor,
  }) async {
    final manifest = await validateManifest(archiveFile);

    final dbPath = dbHandle.current.path;

    // Safety net BEFORE any live file is touched. The returned snapshot is also
    // the automatic rollback source if the swapped-in database fails to open.
    final snapshot = await _takePreRestoreSnapshot();

    // Stage `brewline.db` + `images/` as a sibling of the database file so the
    // swaps below are same-filesystem renames (an atomic move, not a copy).
    final stage = Directory(
      p.join(p.dirname(dbPath), '.brewline_restore_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await stage.create();

    try {
      final entries = readBackupArchive(archiveFile);

      final restoredDb = entries['brewline.db'];
      if (restoredDb == null) {
        throw const BackupCorruptArchiveException(
          'Archive has no brewline.db — not a brewline backup',
        );
      }
      await File(p.join(stage.path, kBrewlineDatabaseName)).writeAsBytes(
        restoredDb,
        flush: true,
      );
      await _stageImages(
        stage,
        entries.entries.where((e) => e.key.startsWith('images/')).toList(),
      );

      // Nothing may hold the database file open before we move it.
      await dbHandle.close();

      // sqflite opens the app database in WAL mode on Android (and FFI). A
      // `-wal`/`-shm` pair left next to the file after close would be replayed
      // against the newly swapped-in database during reopen — applying pages
      // from the *previous* database onto the restored file, or blocking the
      // reopen outright. Wipe any leftovers so the restored file is opened as
      // the single source of truth. Nothing is lost: the pre-restore snapshot
      // taken above holds all current data.
      _removeJournalSidecars(dbPath);

      try {
        await _swapFile(
          File(p.join(stage.path, kBrewlineDatabaseName)),
          File(dbPath),
        );
        await _swapDirectory(
          Directory(p.join(stage.path, 'images')),
          imagesDirectory,
        );
      } on FileSystemException catch (e) {
        throw BackupRestoreException('File swap failed: $e');
      }

      // Reopen the restored database — migrations run here for older schemas.
      final Database reopened;
      try {
        reopened = await dbHandle.reopen(factory: factory, path: dbPath);
        // Cheap sanity read: a reopen can appear to succeed even when the file
        // at [dbPath] is not a readable database (a stale journal replay or a
        // partial swap leaves it malformed). Verifying before the audit write
        // lets a bad restore roll itself back and surface as a real error
        // instead of coming back up half-restored (or hanging later).
        await reopened.query('sqlite_master', limit: 1);
      } catch (e) {
        await _rollbackToSnapshot(snapshot.path, dbPath, dbHandle);
        throw BackupRestoreException('Restored database failed to open: $e');
      }

      // Audit AFTER the swap+reopen, against the restored data itself.
      await AuditRepository(reopened).logEvent(
        eventType: 'backup_restored',
        actor: actor,
        metadata: jsonEncode({
          'schemaVersion': manifest.schemaVersion,
          'appVersion': manifest.appVersion,
          'createdAt': manifest.createdAt.toIso8601String(),
        }),
      );

      // Re-arm the login credential + onboarding flag from the archive (see
      // _applyCredential). Done last so a failed swap/reopen leaves auth state
      // untouched.
      await _applyCredential(entries);

      return BackupRestoreResult(manifest: manifest);
    } finally {
      await stage.delete(recursive: true);
    }
  }

  /// `VACUUM INTO` the live [database] into [target] (a compacted, consistent,
  /// openable snapshot). Falls back to `PRAGMA wal_checkpoint(TRUNCATE)` + a
  /// plain file copy on bundled SQLite older than 3.27 (notably some Android
  /// devices), which is the same single-writer view on this app's one
  /// connection.
  Future<void> _vacuumInto(File target) async {
    await Directory(p.dirname(target.path)).create(recursive: true);
    final escaped = target.path.replaceAll("'", "''");
    try {
      await database.execute("VACUUM INTO '$escaped'");
    } on DatabaseException {
      await database.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
      await File(database.path).copy(target.path);
    }
  }

  Future<File> _takePreRestoreSnapshot() async {
    await snapshotDirectory.create(recursive: true);
    final target = File(
      p.join(
        snapshotDirectory.path,
        'pre-restore-${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );
    await _vacuumInto(target);
    await _pruneSnapshots();
    return target;
  }

  /// Keeps only the most recent [kPreRestoreSnapshotsToKeep] pre-restore
  /// snapshots, deleting the older ones so the directory can't grow forever.
  Future<void> _pruneSnapshots() async {
    final files = snapshotDirectory
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('pre-restore-'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (files.length <= kPreRestoreSnapshotsToKeep) return;
    final oldest = files.sublist(0, files.length - kPreRestoreSnapshotsToKeep);
    for (final file in oldest) {
      await file.delete();
    }
  }

  Future<void> _exportPreferences(Directory staging) async {
    final export = <String, Object?>{};
    for (final key in preferences.getKeys()) {
      final value = preferences.get(key);
      if (value is String ||
          value is bool ||
          value is num ||
          value is List<String>) {
        export[key] = value;
      }
    }
    await File(p.join(staging.path, 'preferences.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(export),
    );
  }

  /// Packs the admin credential into `credential.json` so a backup is
  /// self-sufficient for logging in after restore — the credential store is
  /// secure storage on mobile (not part of the preferences snapshot) and
  /// SharedPreferences on desktop, so it can't be guessed from platform.
  ///
  /// Missing/absent credential (never set up, or an embedded store result
  /// failure) just skips the entry — restoring such a backup keeps the current
  /// device's credential.
  Future<void> _exportCredential(Directory staging) async {
    final store = credentialStore;
    if (store == null) return;
    final credential = await store.read();
    if (credential == null) return;
    await File(p.join(staging.path, 'credential.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'username': credential.username,
        'pinHash': credential.pinHash,
        'pinSalt': credential.pinSalt,
      }),
    );
  }

  /// Re-arms the admin credential + onboarding flag from the archive's
  /// `credential.json` (written by [_exportCredential]). The result is that
  /// after the app restart the login screen is reachable and the restored
  /// admin PIN works — this is what "restored data credentials" means.
  ///
  /// Never throws and never blocks restore for long: the database swap is
  /// already committed the moment this runs, so the only acceptable outcomes
  /// are "credential re-armed" or "restore still completes and the app
  /// restarts" — see [kCredentialWriteTimeout].
  Future<void> _applyCredential(Map<String, Uint8List> entries) async {
    final store = credentialStore;
    final raw = entries['credential.json'];
    if (store == null || raw == null) return;

    final Map<String, dynamic> credential;
    try {
      final decoded = jsonDecode(utf8.decode(raw));
      if (decoded is! Map<String, dynamic>) return;
      credential = decoded;
    } on FormatException {
      return;
    }

    final username = credential['username'];
    final pinHash = credential['pinHash'];
    final pinSalt = credential['pinSalt'];
    if (username is! String || pinHash is! String) return;

    // The onboarding flag is plain SharedPreferences — fast and reliable — so
    // it is written first: it decides Login-vs-Onboarding on the restart that
    // follows the restore, and is required regardless of what the keystore
    // write does.
    await preferences.setBool(kOnboardingCompleteKey, true);

    // The credential itself goes through whatever platform backend the store
    // is (secure storage on mobile, prefs on desktop). On Android the secure-
    // storage platform channel has been observed to hang; time-boxing the write
    // means a stuck keystore can never wedge the whole restore in its progress
    // dialog forever. On failure the admin still lands on the login screen and
    // authenticates against whatever credential the app already had.
    final storedCredential = AdminCredential(
      username: username,
      pinHash: pinHash,
      pinSalt: pinSalt is String ? pinSalt : null,
    );
    try {
      await store.write(storedCredential).timeout(kCredentialWriteTimeout);
    } catch (_) {
      // Best-effort re-arm; never fail the restore for a keystore hiccup.
    }
  }

  /// Deletes any SQLite journal sidecars (`-wal`/`-shm`) next to [dbPath] so
  /// the freshly swapped-in database is opened as the single source of truth.
  ///
  /// sqflite opens databases in WAL mode on Android and FFI; a `-wal`/`-shm`
  /// pair left from the *previous* connection can survive a less-than-perfect
  /// close and would be replayed over the restored file during reopen, applying
  /// stale pages (or blocking). Safe to remove after [AppDatabaseHandle.close]:
  /// a clean close has checkpointed them, and the pre-restore snapshot holds
  /// anything else.
  void _removeJournalSidecars(String dbPath) {
    for (final suffix in const ['-wal', '-shm']) {
      final sidecar = File('$dbPath$suffix');
      try {
        if (sidecar.existsSync()) sidecar.deleteSync();
      } on FileSystemException {
        // Best-effort; the swap below still proceeds.
      }
    }
  }

  /// Rolls the live database back to [snapshotPath] (a pre-restore `VACUUM
  /// INTO` copy) after a restore failed at open-time, so the running app keeps
  /// working against its previous data instead of a half-restored file.
  ///
  /// Product images are not rolled back: the swap already deleted the old
  /// `images/` set, and missing product photos degrade gracefully. Only the
  /// database — the single source of truth — is critical to restore.
  Future<void> _rollbackToSnapshot(
    String snapshotPath,
    String dbPath,
    AppDatabaseHandle dbHandle,
  ) async {
    await dbHandle.close();
    _removeJournalSidecars(dbPath);

    final current = File(dbPath);
    if (await current.exists()) {
      try {
        await current.delete();
      } on FileSystemException {
        // Best-effort delete; the snapshot rename below may still win.
      }
    }

    final snapshotFile = File(snapshotPath);
    if (await snapshotFile.exists()) {
      try {
        await snapshotFile.rename(dbPath);
      } on FileSystemException {
        // Cross-device: fall back to a copy rather than failing the rollback.
        await snapshotFile.copy(dbPath);
      }
    }

    await dbHandle.reopen(factory: factory, path: dbPath);
  }

  Future<void> _copyImages(Directory staging) async {
    if (!await imagesDirectory.exists()) return;
    final target = Directory(p.join(staging.path, 'images'));
    await target.create();
    await for (final entity in imagesDirectory.list()) {
      if (entity is File) {
        await entity.copy(p.join(target.path, p.basename(entity.path)));
      }
    }
  }

  Future<void> _stageImages(
    Directory stage,
    List<MapEntry<String, List<int>>> images,
  ) async {
    if (images.isEmpty) return;
    final target = Directory(p.join(stage.path, 'images'));
    await target.create(recursive: true);
    for (final entry in images) {
      // Archive keys are images/<basename> — drop the directory segment.
      await File(p.join(target.path, p.basename(entry.key))).writeAsBytes(
        entry.value,
        flush: true,
      );
    }
  }

  /// Moves [source] onto [target], first renaming the existing target aside so
  /// the swap is: move-old-aside → rename-new-into-place → delete-old. If
  /// anything fails the old file is renamed back.
  Future<void> _swapFile(File source, File target) async {
    final backup = File('${target.path}.pre_restore');
    if (await target.exists()) {
      if (await backup.exists()) await backup.delete();
      await target.rename(backup.path);
    }
    try {
      try {
        await source.rename(target.path);
      } on FileSystemException {
        // Cross-device rename (staging next to the db should make this rare);
        // fall back to a direct copy rather than failing the restore.
        await source.copy(target.path);
      }
    } catch (_) {
      if (await backup.exists() && !await target.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
    if (await backup.exists()) await backup.delete();
  }

  /// Atomic-ish directory swap for the product-image store: rename the old
  /// directory aside, rename the restored one into place, roll back on
  /// failure. Cross-device renames (tmpfs `/tmp` vs a disk documents dir)
  /// degrade to a copy-based swap.
  Future<void> _swapDirectory(Directory source, Directory target) async {
    if (!await source.exists()) return; // archive had no images — keep current

    final backup = Directory('${target.path}.pre_restore');
    var moved = false;
    if (await target.exists()) {
      if (await backup.exists()) await backup.delete(recursive: true);
      try {
        await target.rename(backup.path);
        moved = true;
      } on FileSystemException {
        moved = false;
        await backup.delete(recursive: true);
      }
    }
    try {
      if (moved) {
        await source.rename(target.path);
      } else {
        // No shared filesystem: copy the restored images over the current set.
        await target.create(recursive: true);
        for (final entity in source.listSync()) {
          if (entity is File) {
            await entity.copy(p.join(target.path, p.basename(entity.path)));
          }
        }
      }
      if (await backup.exists()) {
        await backup.delete(recursive: true);
      }
    } catch (_) {
      if (moved && await backup.exists() && !await target.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }

  /// Optional free-text device label ("Front Counter"), persisted once per
  /// device and embedded in every manifest so an admin with several backup
  /// files can tell them apart.
  String? _deviceLabel() {
    final label = preferences.getString(kDeviceLabelKey)?.trim();
    return (label == null || label.isEmpty) ? null : label;
  }
}
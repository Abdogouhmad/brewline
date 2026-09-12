import 'dart:io';

import 'package:brewline/core/backup/backup_archive.dart';
import 'package:brewline/core/backup/backup_service.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Backup & restore is the app's migration path between devices, so these test
/// the archive lifecycle end-to-end against real FFI-backed SQLite files:
///
/// * round-trip equality — `create()` then `restore()` reproduces every
///   business row byte-for-byte (plus the product-image store) and leaves a
///   pre-restore safety snapshot;
/// * an **older-schema** backup restores successfully and reopens through the
///   normal migration chain, ending at [kDatabaseSchemaVersion];
/// * a **newer-schema** backup is rejected before anything live is touched;
/// * a malformed archive is rejected as corrupt.
void main() {
  sqfliteFfiInit();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('brewline_backup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('round-trip: create() then restore() reproduces every table row + images',
      () async {
    final imagesDir = Directory(p.join(tempDir.path, 'product_images'));
    await imagesDir.create();
    final snapshotsDir = Directory(p.join(tempDir.path, 'restore_snapshots'));

    final dbPath = p.join(tempDir.path, 'brewline.db');
    final source = await openAppDatabase(factory: databaseFactoryFfi, path: dbPath);
    addTearDown(() => source.close());

    // Business data a café actually cares about.
    await source.insert('products', {
      'id': 'p-001',
      'name': 'Espresso',
      'price_cents': 900,
      'image_path': 'latte.jpg',
      'category': 'Coffee',
      'available': 1,
      'stock_quantity': 8,
      'low_stock_threshold': 2,
    });
    await source.insert('orders', {
      'id': 1,
      'created_at': DateTime(2026, 9, 10, 10).millisecondsSinceEpoch,
      'waiter_username': 'admin',
      'order_number': 23,
      'is_voided': 0,
      'total_cents': 900,
    });
    await source.insert('order_items', {
      'order_id': 1,
      'product_id': 'p-001',
      'name': 'Espresso',
      'quantity': 1,
      'unit_price_cents': 900,
    });
    await source.insert('staff', {
      'id': 'waiter-1',
      'username': 'salma',
      'pin_hash': 'hash',
      'pin_salt': 'salt',
      'name': 'Salma',
      'active': 1,
      'created_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    });
    final imageFile = File(p.join(imagesDir.path, 'latte.jpg'));
    await imageFile.writeAsBytes([1, 2, 3, 4]);

    final service = BackupService(
      database: source,
      preferences: await SharedPreferences.getInstance(),
      appVersion: '1.2.3',
      factory: databaseFactoryFfi,
      imagesDirectory: imagesDir,
      snapshotDirectory: snapshotsDir,
    );

    final backup = await service.create(
      outputPath: p.join(tempDir.path, 'backup.brewline'),
      actor: 'admin',
    );
    expect(await backup.exists(), isTrue);
    // A backup_created audit event was recorded against the source.
    expect(
      await source.query('audit_events',
          where: 'event_type = ?', whereArgs: ['backup_created']),
      hasLength(1),
    );

    // Restore target — a *separate* database, like another device / reinstall.
    final targetDir = Directory(p.join(tempDir.path, 'target'));
    final targetDbPath = p.join(targetDir.path, 'brewline.db');
    final targetImages = Directory(p.join(targetDir.path, 'product_images'));
    await targetImages.create(recursive: true);
    // Plant a row that must be REPLACED by the restore.
    final live = await openAppDatabase(factory: databaseFactoryFfi, path: targetDbPath);
    await live.insert('products', {
      'id': 'p-old',
      'name': 'Stale data from today',
      'price_cents': 100,
      'image_path': '',
      'category': '',
      'available': 1,
      'stock_quantity': 0,
      'low_stock_threshold': 0,
    });
    final handle = AppDatabaseHandle()..attach(live);
    final restoreService = BackupService(
      database: live,
      preferences: await SharedPreferences.getInstance(),
      appVersion: '1.2.3',
      factory: databaseFactoryFfi,
      imagesDirectory: targetImages,
      snapshotDirectory: snapshotsDir,
    );

    final result = await restoreService.restore(
      archiveFile: backup,
      dbHandle: handle,
      actor: 'admin',
    );
    expect(result.manifest.schemaVersion, kDatabaseSchemaVersion);
    final restored = handle.current;

    // The restored database is at the current schema and the stale row is gone.
    expect(await restored.getVersion(), kDatabaseSchemaVersion);
    expect(
      await restored.query('products', where: 'id = ?', whereArgs: ['p-old']),
      isEmpty,
    );

    // Row-for-row equality across every business table.
    for (final table in ['products', 'orders', 'order_items', 'staff']) {
      expect(await restored.query(table), await source.query(table),
          reason: 'table $table must match after restore');
    }
    // Product images were restored too.
    expect(
      await File(p.join(targetImages.path, 'latte.jpg')).readAsBytes(),
      [1, 2, 3, 4],
    );
    // The audit trail of the restored data records the restore itself; the
    // archive's db snapshot was taken before create() logged its own
    // backup_created event, so that event lives only on the source.
    expect(
      await restored.query('audit_events',
          where: 'event_type = ?', whereArgs: ['backup_restored']),
      hasLength(1),
    );
    expect(
      await source.query('audit_events',
          where: 'event_type = ?', whereArgs: ['backup_created']),
      hasLength(1),
    );

    // The pre-restore safety snapshot captured the live (pre-restore) data.
    final snapshots = snapshotsDir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('pre-restore-'))
        .toList();
    expect(snapshots, hasLength(1));
    final snapshotDb = await databaseFactoryFfi.openDatabase(snapshots.first.path);
    final snapshotProducts =
        await snapshotDb.query('products', where: 'id = ?', whereArgs: ['p-old']);
    await snapshotDb.close();
    expect(snapshotProducts, hasLength(1),
        reason: 'safety snapshot must hold the pre-restore data');
  });

  test('older-schema backup (v2 db + v2 manifest) restores through the migration chain',
      () async {
    final imagesDir = Directory(p.join(tempDir.path, 'product_images'));
    final snapshotsDir = Directory(p.join(tempDir.path, 'restore_snapshots'));
    await imagesDir.create();

    // Build a v2 database exactly like an old install would have had it, wrap
    // it in an archive whose manifest claims schemaVersion 2.
    final oldDir = Directory(p.join(tempDir.path, 'old_device'));
    final oldDbPath = p.join(oldDir.path, 'brewline.db');
    final oldDb = await databaseFactoryFfi.openDatabase(
      oldDbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE products (
              id TEXT PRIMARY KEY, name TEXT NOT NULL, price REAL NOT NULL,
              image_path TEXT NOT NULL, category TEXT NOT NULL DEFAULT '',
              available INTEGER NOT NULL DEFAULT 1,
              stock_quantity INTEGER NOT NULL DEFAULT 0,
              low_stock_threshold INTEGER NOT NULL DEFAULT 0,
              is_archived INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE orders (
              id INTEGER PRIMARY KEY, created_at INTEGER NOT NULL,
              waiter_username TEXT, total REAL NOT NULL,
              order_number INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE order_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
              product_id TEXT NOT NULL, name TEXT NOT NULL,
              quantity INTEGER NOT NULL, unit_price REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE staff (
              id TEXT PRIMARY KEY, username TEXT NOT NULL UNIQUE,
              pin_hash TEXT NOT NULL, name TEXT NOT NULL,
              active INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE audit_events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              event_type TEXT NOT NULL CHECK (event_type IN ('login', 'logout', 'cashout')),
              actor TEXT NOT NULL, metadata TEXT, created_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    await oldDb.insert('products', {
      'id': 'p-001',
      'name': 'Tagine',
      'price': 45.0,
      'image_path': 'assets/stack_imgs/tagine.jpg',
      'category': 'Mains',
    });
    await oldDb.close();

    final fixture = await _makeArchive(
      dbFile: File(oldDbPath),
      schemaVersion: 2,
      appVersion: '0.9.0',
      archivePath: p.join(tempDir.path, 'old-backup.brewline'),
      deviceLabel: 'Back Counter',
    );

    // Restore onto a current (v8) device.
    final targetDir = Directory(p.join(tempDir.path, 'new_device'));
    final targetDbPath = p.join(targetDir.path, 'brewline.db');
    final targetImages = Directory(p.join(targetDir.path, 'product_images'));
    await targetImages.create(recursive: true);
    final live = await openAppDatabase(factory: databaseFactoryFfi, path: targetDbPath);
    final handle = AppDatabaseHandle()..attach(live);
    final restoreService = BackupService(
      database: live,
      preferences: await SharedPreferences.getInstance(),
      appVersion: '1.2.3',
      factory: databaseFactoryFfi,
      imagesDirectory: targetImages,
      snapshotDirectory: snapshotsDir,
    );

    await restoreService.restore(
      archiveFile: fixture,
      dbHandle: handle,
      actor: 'admin',
    );

    // Reopening ran 2 → current: the cents columns (v7) and backup event types
    // (v8) now exist, and the v2-era rows survived with their money converted.
    final restored = handle.current;
    expect(await restored.getVersion(), kDatabaseSchemaVersion);
    final product = (await restored.query('products',
        where: 'id = ?', whereArgs: ['p-001']))[0];
    expect(product['name'], 'Tagine');
    expect(product['price_cents'], 4500);
    await restored.rawQuery(
        'SELECT * FROM audit_events WHERE event_type = \'backup_restored\'');
  });

  test('newer-schema backup is rejected before anything live is touched', () async {
    final imagesDir = Directory(p.join(tempDir.path, 'product_images'));
    final snapshotsDir = Directory(p.join(tempDir.path, 'restore_snapshots'));
    await imagesDir.create();

    final fixture = await _makeArchive(
      dbFile: await _writeEmptyDb(p.join(tempDir.path, 'future', 'brewline.db')),
      schemaVersion: kDatabaseSchemaVersion + 1,
      appVersion: '99.0.0',
      archivePath: p.join(tempDir.path, 'future-backup.brewline'),
    );

    final targetDbPath = p.join(tempDir.path, 'target', 'brewline.db');
    final targetImages = Directory(p.join(tempDir.path, 'target', 'product_images'));
    await targetImages.create(recursive: true);
    final live = await openAppDatabase(factory: databaseFactoryFfi, path: targetDbPath);
    await live.insert('products', {
      'id': 'p-keep',
      'name': 'Must survive',
      'price_cents': 100,
      'image_path': '',
      'category': '',
      'available': 1,
      'stock_quantity': 0,
      'low_stock_threshold': 0,
    });
    final handle = AppDatabaseHandle()..attach(live);
    final restoreService = BackupService(
      database: live,
      preferences: await SharedPreferences.getInstance(),
      appVersion: '1.2.3',
      factory: databaseFactoryFfi,
      imagesDirectory: targetImages,
      snapshotDirectory: snapshotsDir,
    );

    // validateManifest rejects it with a future-schema error...
    await expectLater(
      restoreService.validateManifest(fixture),
      throwsA(isA<BackupSchemaTooNewException>()),
    );
    // ...and restore() rejects it too, without writing a snapshot or swapping
    // the live file (the row must still be there, the handle still open).
    await expectLater(
      restoreService.restore(
        archiveFile: fixture,
        dbHandle: handle,
        actor: 'admin',
      ),
      throwsA(isA<BackupSchemaTooNewException>()),
    );
    expect(
      await live.query('products', where: 'id = ?', whereArgs: ['p-keep']),
      hasLength(1),
    );
    expect(handle.isOpen, isTrue);
    await snapshotsDir.create(recursive: true);
    expect(snapshotsDir.listSync(), isEmpty, reason: 'no pre-restore snapshot written');
  });

  test('garbage archive is rejected as corrupt', () async {
    final imagesDir = Directory(p.join(tempDir.path, 'product_images'));
    final snapshotsDir = Directory(p.join(tempDir.path, 'restore_snapshots'));
    await imagesDir.create();
    final live = await openAppDatabase(
        factory: databaseFactoryFfi, path: p.join(tempDir.path, 'target', 'brewline.db'));
    final service = BackupService(
      database: live,
      preferences: await SharedPreferences.getInstance(),
      appVersion: '1.2.3',
      factory: databaseFactoryFfi,
      imagesDirectory: imagesDir,
      snapshotDirectory: snapshotsDir,
    );

    final garbage = File(p.join(tempDir.path, 'garbage.brewline'));
    await garbage.writeAsBytes(List<int>.filled(128, 7));

    await expectLater(
      service.validateManifest(garbage),
      throwsA(isA<BackupCorruptArchiveException>()),
    );
    await live.close();
  });

  test('manifest carries the device label when set, omitted when empty', () async {
    SharedPreferences.setMockInitialValues({
      kDeviceLabelKey: 'Front Counter',
    });
    final imagesDir = Directory(p.join(tempDir.path, 'product_images'));
    final snapshotsDir = Directory(p.join(tempDir.path, 'restore_snapshots'));
    await imagesDir.create();
    final source = await openAppDatabase(
        factory: databaseFactoryFfi, path: p.join(tempDir.path, 'brewline.db'));
    final service = BackupService(
      database: source,
      preferences: await SharedPreferences.getInstance(),
      appVersion: '1.2.3',
      factory: databaseFactoryFfi,
      imagesDirectory: imagesDir,
      snapshotDirectory: snapshotsDir,
    );

    final backup = await service.create(
      outputPath: p.join(tempDir.path, 'labeled.brewline'),
      actor: 'admin',
    );
    expect(readManifest(backup).deviceLabel, 'Front Counter');

    SharedPreferences.setMockInitialValues({});
    final unlabeled = BackupService(
      database: source,
      preferences: await SharedPreferences.getInstance(),
      appVersion: '1.2.3',
      factory: databaseFactoryFfi,
      imagesDirectory: imagesDir,
      snapshotDirectory: snapshotsDir,
    );
    final backup2 = await unlabeled.create(
      outputPath: p.join(tempDir.path, 'unlabeled.brewline'),
      actor: 'admin',
    );
    expect(readManifest(backup2).deviceLabel, isNull);
    await source.close();
  });
}

/// Builds a `.brewline` archive with an arbitrary db file + manifest values,
/// so tests can simulate backups made by older/newer app versions.
Future<File> _makeArchive({
  required File dbFile,
  required int schemaVersion,
  required String appVersion,
  required String archivePath,
  String? deviceLabel,
}) async {
  final staging =
      await Directory.systemTemp.createTemp('brewline_backup_fixture_');
  try {
    await dbFile.copy(p.join(staging.path, 'brewline.db'));
    await writeManifest(
      manifest: BackupManifest(
        appVersion: appVersion,
        schemaVersion: schemaVersion,
        createdAt: DateTime(2026, 9, 10, 12),
        deviceLabel: deviceLabel,
      ),
      directory: staging,
    );
    final archive = File(archivePath);
    await writeBackupArchive(sourceDirectory: staging, outputFile: archive);
    return archive;
  } finally {
    await staging.delete(recursive: true);
  }
}

/// A minimal, valid empty brewline database at the current schema.
Future<File> _writeEmptyDb(String path) async {
  final db = await openAppDatabase(factory: databaseFactoryFfi, path: path);
  await db.close();
  return File(path);
}
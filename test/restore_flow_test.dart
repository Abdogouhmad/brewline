import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:brewline/core/app_restart.dart';
import 'package:brewline/core/backup/backup_archive.dart';
import 'package:brewline/core/backup/backup_service.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/security/credential_store.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/features/admin/providers/backup_provider.dart';
import 'package:brewline/features/admin/widgets/settings/data_section.dart';
import 'package:brewline/l10n/app_localizations.dart';

class _FakeFileSelector extends FileSelectorPlatform {
  final XFile file;
  _FakeFileSelector(this.file);

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async =>
      file;
}

/// Deterministic stand-in: the real [BackupService] restore does live database
/// + filesystem work that deliberately starves under FakeAsync — it is covered
/// separately by the direct round-trip test. This fake exercises the UI wiring
/// (picker → PIN dialog → restore invoked → app restart) instead.
class _FakeBackupService extends BackupService {
  int restoreCalls = 0;
  int validateCalls = 0;
  Exception? restoreError;

  _FakeBackupService({required super.database, required super.preferences})
      : super(
          appVersion: '1.2.3',
          factory: databaseFactoryFfi,
          imagesDirectory: Directory(p.join(Directory.systemTemp.path, 'img')),
          snapshotDirectory:
              Directory(p.join(Directory.systemTemp.path, 'snap')),
        );

  BackupManifest get _manifest => BackupManifest(
        appVersion: '1.2.3',
        schemaVersion: kDatabaseSchemaVersion,
        createdAt: DateTime(2026, 1, 1),
        deviceLabel: null,
      );

  @override
  Future<BackupManifest> validateManifest(File archiveFile) {
    validateCalls++;
    return Future.value(_manifest);
  }

  @override
  Future<BackupRestoreResult> restore({
    required File archiveFile,
    required AppDatabaseHandle dbHandle,
    required String actor,
  }) async {
    restoreCalls++;
    final error = restoreError;
    if (error != null) throw error;
    return BackupRestoreResult(manifest: _manifest);
  }
}

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late SharedPreferences prefs;
  late Database fakeDb;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    tempDir = Directory.systemTemp.createTempSync('restore_flow_');
    // A real app database (full schema) so the PIN gate's `staff` lookup —
    // which reads `staffRepositoryProvider` → `appDatabaseProvider` — resolves
    // inside the widget tests instead of opening the production database.
    fakeDb = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: p.join(tempDir.path, 'fake.db'),
    );
    final salt = generateSalt();
    await prefs.setString(kAdminUsernameKey, 'admin');
    await prefs.setString(kAdminPinHashKey, hashPin('1234', salt));
    await prefs.setString(kAdminPinSaltKey, salt);
  });

  tearDown(() async {
    await fakeDb.close();
    tempDir.deleteSync(recursive: true);
  });

  test('real service round-trip restores the same connection the app uses',
      () async {
    final dbPath = p.join(tempDir.path, 'brewline.db');
    final live = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: dbPath,
    );
    await live.insert('products', {
      'id': 'p-live',
      'name': 'Live product',
      'price_cents': 500,
      'image_path': '',
      'category': 'Coffee',
      'available': 1,
      'stock_quantity': 3,
      'low_stock_threshold': 1,
      'is_archived': 0,
    });

    final handle = AppDatabaseHandle()..attach(live);
    final service = BackupService(
      database: live,
      preferences: prefs,
      appVersion: '1.2.3',
      factory: databaseFactoryFfi,
      imagesDirectory: Directory(p.join(tempDir.path, 'product_images')),
      snapshotDirectory: Directory(p.join(tempDir.path, 'restore_snapshots')),
    );

    final backupPath = await service.create(
      outputPath: p.join(tempDir.path, 'backup.brewline'),
      actor: 'admin',
    );
    // Plant stale data that a restore must revert.
    await live.insert('products', {
      'id': 'p-stale',
      'name': 'Stale',
      'price_cents': 100,
      'image_path': '',
      'category': '',
      'available': 1,
      'stock_quantity': 0,
      'low_stock_threshold': 0,
      'is_archived': 0,
    });

    final result = await service.restore(
      archiveFile: backupPath,
      dbHandle: handle,
      actor: 'admin',
    );
    expect(result.manifest.schemaVersion, kDatabaseSchemaVersion);
    final stale = await handle.current
        .query('products', where: 'id = ?', whereArgs: ['p-stale']);
    expect(stale, isEmpty);
    handle.close();
  });

  testWidgets('restore button runs restore and restarts the app',
      (tester) async {
    FileSelectorPlatform.instance = _FakeFileSelector(XFile('backup.brewline'));
    final service = _FakeBackupService(
      database: fakeDb,
      preferences: prefs,
    );

    var restarted = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) async => fakeDb),
          appDatabaseHandleProvider.overrideWithValue(
            AppDatabaseHandle()..attach(fakeDb),
          ),
          backupServiceProvider.overrideWith((ref) => Future.value(service)),
          credentialStoreProvider.overrideWithValue(
            PrefsCredentialStore(prefs),
          ),
          appRestartProvider.overrideWithValue(() async {
            restarted = true;
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DataSection()),
        ),
      ),
    );

    // Tap "Restore from file".
    await tester.tap(find.text('Restore from file'));
    await tester.pumpAndSettle();
    expect(service.validateCalls, 1);

    // The manifest summary dialog appears.
    expect(find.text('Restore backup?'), findsOneWidget);

    // Enter the admin PIN and confirm.
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(service.restoreCalls, 1, reason: 'restore must be invoked');
    expect(restarted, isTrue, reason: 'appRestart must run after a restore');
  });

  testWidgets('a failing restore surfaces an error and does NOT restart',
      (tester) async {
    FileSelectorPlatform.instance = _FakeFileSelector(XFile('backup.brewline'));
    final service = _FakeBackupService(
      database: fakeDb,
      preferences: prefs,
    )..restoreError = const BackupRestoreException('boom');

    var restarted = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) async => fakeDb),
          appDatabaseHandleProvider.overrideWithValue(
            AppDatabaseHandle()..attach(fakeDb),
          ),
          backupServiceProvider.overrideWith((ref) => Future.value(service)),
          credentialStoreProvider.overrideWithValue(
            PrefsCredentialStore(prefs),
          ),
          appRestartProvider.overrideWithValue(() async {
            restarted = true;
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: DataSection()),
        ),
      ),
    );

    await tester.tap(find.text('Restore from file'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();

    expect(service.restoreCalls, 1);
    expect(find.text('Restore failed'), findsOneWidget,
        reason: 'the error snack bar must show instead of silent failure');
    expect(restarted, isFalse,
        reason: 'failed restore must not restart the app');
  });
}
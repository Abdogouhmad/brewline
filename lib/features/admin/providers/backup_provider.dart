/// Riverpod wiring for the backup & restore feature (settings **Data** section,
/// admin-only).
///
/// Exposes the [BackupService] (built from the live database, preferences, the
/// installed app version and the platform's product-image + snapshot
/// directories), the persisted "last backup" timestamp and the device label
/// used in backup manifests.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:brewline/core/backup/backup_service.dart';
import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/security/credential_store.dart';
import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/services/product_image_store.dart';
import 'package:brewline/core/theme/theme_controller.dart'
    show sharedPreferencesProvider;

/// SharedPreferences key holding the last *successful* backup timestamp.
const String kLastBackupAtKey = 'last_backup_at_ms';

/// Last successful backup, `null` when the device has never backed up.
///
/// Persisted with the same SharedPreferences pattern as the OTA plan's
/// `last_update_check_at`, so it survives restarts and — deliberately — stays
/// visible as a passive reminder in the Data section (§3.4 of the backup spec).
final lastBackupAtProvider = NotifierProvider<LastBackupAtNotifier, DateTime?>(
  LastBackupAtNotifier.new,
);

class LastBackupAtNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final ms = prefs.getInt(kLastBackupAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markBackedUp(DateTime at) async {
    state = at;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(kLastBackupAtKey, at.millisecondsSinceEpoch);
  }
}

/// Optional free-text device label ("Front Counter") embedded in every
/// manifest so an admin with several backup files can tell them apart. Set
/// once per device, persisted in SharedPreferences.
final deviceLabelProvider = NotifierProvider<DeviceLabelNotifier, String>(
  DeviceLabelNotifier.new,
);

class DeviceLabelNotifier extends Notifier<String> {
  @override
  String build() =>
      ref.watch(sharedPreferencesProvider).getString(kDeviceLabelKey) ?? '';

  Future<void> setLabel(String label) async {
    state = label;
    await ref
        .read(sharedPreferencesProvider)
        .setString(kDeviceLabelKey, label.trim());
  }
}

/// The [BackupService] for the running app: resolved against the live database
/// connection, the persisted preferences, the installed app version and the
/// platform's product-image + snapshot directories.
final backupServiceProvider = FutureProvider<BackupService>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  final prefs = ref.watch(sharedPreferencesProvider);
  final appInfo = await ref.watch(appInfoProvider.future);
  final docs = await getApplicationDocumentsDirectory();
  return BackupService(
    database: db,
    preferences: prefs,
    appVersion: appInfo.version,
    imagesDirectory: Directory(p.join(docs.path, kProductImagesDir)),
    snapshotDirectory: Directory(p.join(docs.path, 'restore_snapshots')),
    credentialStore: ref.read(credentialStoreProvider),
  );
});
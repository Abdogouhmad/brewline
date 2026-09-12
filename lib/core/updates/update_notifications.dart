/// Local notifications that surface a newly-discovered OTA release.
///
/// BrewLine has no push server — the OTA flow already polls the GitHub
/// Releases API on every launch (the auto-check), so a "push notification"
/// here is a **local notification** fired by that check the first time a new
/// version is seen on a device. On Android it lands in the notification tray
/// of the POS tablet; on Windows/Linux it's a desktop toast. The notification
/// carries the version + first line of the release notes, and tapping it just
/// brings the app to the front where the Settings → Update section shows the
/// full changelog.
///
/// A missing/broken notification service must never break an update check, so
/// [updateNotificationsProvider] defaults to `null` and the only code that
/// overrides it is `main()` — tests (which have no platform plugin) are
/// naturally unaffected.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the platform notification service.
///
/// `null` means "no notifications": tests, platforms where the plugin failed
/// to initialize, or a first launch before the service is ready. [main] wires
/// the initialized instance in via a [ProviderScope] override.
final updateNotificationsProvider = Provider<UpdateNotificationService?>(
  (ref) => null,
);

/// Notification service for OTA update alerts.
class UpdateNotificationService {
  /// A single fixed id is used for the update-available notification, so a
  /// newer check replaces the previous toast instead of stacking duplicates.
  static const int _notificationId = 4201;

  /// The Android notification channel (created lazily by the plugin).
  static const String _channelId = 'ota_updates';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Initialises the plugin per platform and requests notification permission
  /// on Android 13+ (the system shows the permission dialog once; the admin can
  /// change it later in app settings).
  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      windows: WindowsInitializationSettings(
        appName: 'BrewLine',
        appUserModelId: 'brewline.brewline',
        // Stable GUID identifying this app's notifications on Windows.
        guid: '{9E92E0D9-F6E4-4F5B-9B21-6C2E0E1A8C44}',
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Shows the "new version available" notification.
  ///
  /// [summary] is derived from the release notes (`null` when the release has
  /// none — the generic body is used then).
  Future<void> notifyUpdate({
    required String version,
    required String releaseNotes,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'App updates',
        channelDescription:
            'Alerts when a new BrewLine version is available',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.recommendation,
      ),
      windows: WindowsNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    final body = _summaryLine(releaseNotes) ??
        'A new version of BrewLine is ready to install';
    await _plugin.show(
      id: _notificationId,
      title: 'BrewLine $version is available',
      body: body,
      notificationDetails: details,
      payload: version,
    );
  }

  /// First non-empty, markdown-lightened line of the release notes — the
  /// notification body. `null` when the release body is empty.
  String? _summaryLine(String releaseNotes) {
    for (final raw in releaseNotes.split('\n')) {
      final line = raw
          .replaceAll(RegExp(r'^#{1,6}\s+'), '')
          .replaceAll(RegExp(r'^[-*]\s+'), '')
          .replaceAll('*', '')
          .trim();
      if (line.isNotEmpty) return line;
    }
    return null;
  }
}
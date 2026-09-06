import 'package:brewline/core/services/app_info.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/core/updates/update_installer.dart';
import 'package:brewline/core/updates/update_manifest.dart';
import 'package:brewline/core/updates/update_provider.dart';
import 'package:brewline/core/updates/update_service.dart';
import 'package:brewline/features/admin/settings/widgets/update_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAppInfo = AppInfoData(
  appName: 'brewline',
  version: '1.4.2',
  buildNumber: '10',
  packageName: 'brewline',
);

/// A fake [UpdateService] that returns a fixed outcome so the auto-checks
/// triggered by the screen resolve deterministically (never left hanging in
/// [UpdateStatus.checking]).
class _FakeUpdateService extends UpdateService {
  final UpdateCheckResult result;
  final String releaseNotes;

  const _FakeUpdateService({
    this.result = UpdateCheckResult.upToDate,
    this.releaseNotes = '',
  });

  @override
  Future<UpdateCheckOutcome> check({required AppInfoData currentInfo}) async {
    final manifest = UpdateManifest(
      releaseNotes: releaseNotes,
      publishedAt: DateTime.parse('2026-09-06T00:00:00Z'),
      android: result == UpdateCheckResult.upToDate
          ? null
          : const AndroidUpdateInfo(
              latestVersionCode: 11,
              latestVersionName: '1.5.0',
              minSupportedVersionCode: 1,
              mandatory: false,
              apkUrl: 'https://example.com/app-release.apk',
              sha256: '0000000000000000000000000000000000000000000000000000000000000000',
            ),
    );
    return UpdateCheckOutcome(manifest, result);
  }
}

/// Pumps [UpdateScreen] with mock storage and a stable app-info + service.
Future<void> _pumpUpdateScreen(
  WidgetTester tester, {
  UpdateCheckResult result = UpdateCheckResult.upToDate,
  String releaseNotes = '',
  Map<String, Object> storedValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(storedValues);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appInfoProvider.overrideWith((ref) async => _kAppInfo),
        updateServiceProvider.overrideWithValue(
          _FakeUpdateService(result: result, releaseNotes: releaseNotes),
        ),
      ],
      child: const MaterialApp(home: UpdateScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the update header and version details', (tester) async {
    await _pumpUpdateScreen(tester);

    expect(find.text('App update'), findsOneWidget);
    expect(find.text('Version details'), findsOneWidget);
    expect(find.text('Check for updates'), findsWidgets);
    expect(find.text('Current version'), findsOneWidget);
    expect(find.text('Latest version'), findsOneWidget);
    expect(find.text('You are up to date'), findsOneWidget);
    expect(find.text('v1.4.2'), findsOneWidget);
  });

  testWidgets('surfaces an available update with a changelog', (tester) async {
    await _pumpUpdateScreen(
      tester,
      result: UpdateCheckResult.updateAvailable,
      releaseNotes: '### Fixed\n- **Printer** works again\n- Added reports\n',
    );

    expect(find.text('New update available'), findsOneWidget);
    expect(find.text('v1.5.0'), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Fixed'), findsOneWidget);
    expect(find.textContaining('Printer works again'), findsOneWidget);
    expect(find.text('Added reports'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
  });

  testWidgets('auto-check toggle reflects persisted preference', (tester) async {
    await _pumpUpdateScreen(
      tester,
      storedValues: {kAutoCheckUpdatesKey: false},
    );

    final toggle = find.byType(Switch);
    expect(toggle, findsOneWidget);
    expect(tester.widget<Switch>(toggle).value, isFalse);

    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(toggle).value, isTrue);
  });
}
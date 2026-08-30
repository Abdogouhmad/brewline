import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/features/auth/providers/current_user_provider.dart';
import 'package:brewline/features/waiter/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps [SettingsPage] with the SharedPreferences provider overridden
/// (mocked storage) — the same override main() performs at startup. The
/// profile header is bound to the signed-in session, so [currentUserProvider]
/// is pinned to a known waiter to keep the hero card deterministic.
Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  Map<String, Object> storedValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(storedValues);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'staff-1',
            username: 'john',
            name: 'John Doe',
            role: 'Waiter',
          ),
        ),
      ],
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
  // Settle appInfoProvider (PackageInfo platform channel in tests).
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders general, account and printing section cards', (
    tester,
  ) async {
    await _pumpSettingsPage(tester);

    expect(find.text('General'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Account profile'), findsOneWidget);
    expect(find.text('On shift'), findsOneWidget);
    expect(find.text('Printing'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Kitchen receipt'), findsOneWidget);
    expect(find.text('Client receipt'), findsOneWidget);
  });

  testWidgets('receipt switches respect persisted printing preferences', (
    tester,
  ) async {
    await _pumpSettingsPage(
      tester,
      storedValues: {'print_kitchen_receipt': false},
    );

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.first.value, isFalse, reason: 'kitchen receipt off');
    expect(switches.last.value, isTrue, reason: 'client receipt on');
  });

  testWidgets('toggling a receipt switch updates its state', (tester) async {
    await _pumpSettingsPage(tester);

    final clientSwitch = find.byType(Switch).last;
    expect(tester.widget<Switch>(clientSwitch).value, isTrue);

    // The taller page scrolls; bring the switch into view before tapping.
    await tester.ensureVisible(clientSwitch);
    await tester.pumpAndSettle();

    await tester.tap(clientSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(clientSwitch).value, isFalse);
  });
}

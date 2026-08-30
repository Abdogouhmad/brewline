import 'package:brewline/core/db/app_database.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/features/auth/login_page.dart';
import 'package:brewline/features/auth/providers/login_form_provider.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/features/waiter/pages/waiter_home_page.dart';
import 'package:brewline/features/admin/pages/admin_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Database? _db;

/// Seeds the same admin + waiter dummy records the debug seeder writes, plus
/// marks onboarding complete so login is reachable. Waiter accounts live in
/// the SQLite `staff` table, so an in-memory database is set up.
///
/// DB setup does real (FFI) async I/O, which testWidgets' FakeAsync zone does
/// not drive — everything DB-touching runs inside `tester.runAsync`.
Future<void> _seedCredentials(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    kOnboardingCompleteKey: true,
    kAdminUsernameKey: 'admin',
    kAdminPinHashKey: hashPin('1234'),
  });
  await tester.runAsync(() async {
    _db = await openAppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await StaffRepository(_db!).upsert(
      StaffMember(
        id: 'staff-waiter1',
        username: 'waiter1',
        pinHash: hashPin('1111'),
        name: 'Waiter One',
        createdAt: DateTime.now(),
      ),
    );
  });
}

Future<void> _pumpLogin(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWith((ref) async => _db!),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
  });
  await tester.pumpAndSettle();
}

/// Taps the on-screen PIN keypad digits for [pin].
Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final ch in pin.split('')) {
    await tester.tap(find.text(ch));
    await tester.pump();
  }
}

/// Scrolls a widget into view and taps it (forms can overflow the short
/// default test viewport). The tap and the following frames run inside
/// `runAsync` so real SQLite futures (the login lookup, and the journal/catalog
/// queries the next screen starts on its first frame) can complete under the
/// real event loop; frames then settle outside where `pumpAndSettle` drives
/// the UI reliably.
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(finder);
    await tester.pump();
    // Let the login resolve and the routed screen start its data providers.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.pump();
  });
  // Second drain: the routed home launches real SQLite queries while the first
  // block is still running under FakeAsync. Their FFI isolate replies only
  // arrive on the *real* event loop, so give that loop one more un-pumped
  // window; otherwise their loading spinners tick forever and the settle below
  // times out.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 900)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders username field, PIN keypad and login button', (
    tester,
  ) async {
    await _seedCredentials(tester);
    await _pumpLogin(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);

    // No role toggle — the account type is derived from the username.
    expect(find.byType(SegmentedButton), findsNothing);

    // Button starts disabled until a username + full PIN are entered.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Log in'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'admin login succeeds with the real credential and routes to admin',
    (tester) async {
      await _seedCredentials(tester);
      await _pumpLogin(tester);

      await tester.enterText(find.byType(TextFormField), 'admin');
      await tester.pump();
      await _enterPin(tester, '1234');
      await tester.pump();

      await _scrollToAndTap(tester, find.text('Log in'));

      expect(find.byType(AdminHomePage), findsOneWidget);
    },
  );

  testWidgets('waiter login succeeds without any role selection', (
    tester,
  ) async {
    await _seedCredentials(tester);
    await _pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField), 'waiter1');
    await tester.pump();
    await _enterPin(tester, '1111');
    await tester.pump();

    await _scrollToAndTap(tester, find.text('Log in'));

    expect(find.byType(WaiterHomePage), findsOneWidget);

    // The top-bar profile chip shows the database user (the `staff` row's
    // display name), not a hard-coded placeholder.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Waiter One'), findsOneWidget);
  });

  testWidgets(
    'wrong PIN shows a generic error, clears the PIN, keeps the username',
    (tester) async {
      await _seedCredentials(tester);
      await _pumpLogin(tester);

      await tester.enterText(find.byType(TextFormField), 'admin');
      await tester.pump();
      await _enterPin(tester, '000000');
      await tester.pump();

      await _scrollToAndTap(tester, find.text('Log in'));

      expect(find.text('Incorrect username or PIN'), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);

      // No navigation happened.
      expect(find.byType(AdminHomePage), findsNothing);

      // The form still thinks the PIN is empty (it was cleared for retry).
      final state = _providerState(tester);
      expect(state?.pin, isEmpty);

      // The keypad really reset: typing a digit yields a fresh single-digit PIN,
      // not a continuation of the old 4-digit entry.
      await tester.tap(find.text('5'));
      await tester.pump();
      expect(_providerState(tester)?.pin, '5');
    },
  );

  testWidgets(
    'logout from the waiter dashboard returns to login on a clean stack',
    (tester) async {
      await _seedCredentials(tester);
      await _pumpLogin(tester);
      await _loginAsWaiter(tester);

      // On the waiter dashboard now.
      expect(find.byType(WaiterHomePage), findsOneWidget);

      // Trigger logout from the app-bar action -> confirm dialog.
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);

      // Confirm inside runAsync: logout() writes the audit event to SQLite, and
      // that FFI reply only arrives on the real event loop.
      await tester.runAsync(() async {
        await tester.tap(find.text('Log out'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.pump();
      });
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pumpAndSettle();

      // Back on the login screen with the stack cleared.
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(WaiterHomePage), findsNothing);
    },
  );
}

LoginFormState? _providerState(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(LoginPage)),
  );
  return container.read(loginFormProvider);
}

/// Signs in as the seeded dummy waiter (`waiter1` / `1111`).
Future<void> _loginAsWaiter(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField), 'waiter1');
  await tester.pump();
  await _enterPin(tester, '1111');
  await tester.pump();

  await _scrollToAndTap(tester, find.text('Log in'));
}

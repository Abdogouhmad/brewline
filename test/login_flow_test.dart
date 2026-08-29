import 'dart:convert';

import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/core/theme/theme_controller.dart';
import 'package:brewline/features/auth/login_page.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/auth/providers/login_form_provider.dart';
import 'package:brewline/features/auth/widgets/role_segmented_control.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:brewline/features/waiter/pages/waiter_home_page.dart';
import 'package:brewline/features/admin/pages/admin_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seeds the same admin + waiter dummy records the debug seeder writes, plus
/// marks onboarding complete so login is reachable.
Future<void> _seedCredentials() async {
  SharedPreferences.setMockInitialValues({
    kOnboardingCompleteKey: true,
    kAdminUsernameKey: 'admin',
    kAdminPinHashKey: hashPin('123456'),
    kWaiterAccountsKey: jsonEncode({'waiter1': hashPin('111111')}),
  });
}

Future<void> _pumpLogin(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: LoginPage()),
    ),
  );
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
/// default test viewport).
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders role switch, username field and login button', (
    tester,
  ) async {
    await _seedCredentials();
    await _pumpLogin(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Admin username'), findsOneWidget);
    expect(find.byType(RoleSegmentedControl), findsOneWidget);

    // Button starts disabled until a username + full PIN are entered.
    final button =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Log in'));
    expect(button.onPressed, isNull);
  });

  testWidgets('role switch swaps the field labels without navigating', (
    tester,
  ) async {
    await _seedCredentials();
    await _pumpLogin(tester);

    await tester.tap(find.text('Waiter'));
    await tester.pumpAndSettle();

    expect(find.text('Waiter username'), findsOneWidget);
    // Same screen — no dashboard appeared.
    expect(find.byType(AdminHomePage), findsNothing);
    expect(find.byType(WaiterHomePage), findsNothing);
  });

  testWidgets('admin login succeeds with the real credential and routes to admin', (
    tester,
  ) async {
    await _seedCredentials();
    await _pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField), 'admin');
    await tester.pump();
    await _enterPin(tester, '123456');
    await tester.pump();

    await _scrollToAndTap(tester, find.text('Log in'));

    expect(find.byType(AdminHomePage), findsOneWidget);
  });

  testWidgets('waiter login succeeds and routes to waiter dashboard', (
    tester,
  ) async {
    await _seedCredentials();
    await _pumpLogin(tester);

    await tester.tap(find.text('Waiter'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'waiter1');
    await tester.pump();
    await _enterPin(tester, '111111');
    await tester.pump();

    await _scrollToAndTap(tester, find.text('Log in'));

    expect(find.byType(WaiterHomePage), findsOneWidget);
  });

  testWidgets('wrong PIN shows a generic error, clears the PIN, keeps the username', (
    tester,
  ) async {
    await _seedCredentials();
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
  });

  testWidgets('logout from the waiter dashboard returns to login on a clean stack', (
    tester,
  ) async {
    await _seedCredentials();
    await _pumpLogin(tester);
    await _loginAsWaiter(tester);

    // On the waiter dashboard now.
    expect(find.byType(WaiterHomePage), findsOneWidget);

    // Trigger logout from the app-bar action -> confirm dialog.
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    // Back on the login screen with the stack cleared.
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(WaiterHomePage), findsNothing);
  });
}

LoginFormState? _providerState(WidgetTester tester) {
  final container = ProviderScope.containerOf(tester.element(find.byType(LoginPage)));
  return container.read(loginFormProvider);
}

/// Signs in as the seeded dummy waiter (`waiter1` / `111111`).
Future<void> _loginAsWaiter(WidgetTester tester) async {
  await tester.tap(find.text('Waiter'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField), 'waiter1');
  await tester.pump();
  await _enterPin(tester, '111111');
  await tester.pump();

  await _scrollToAndTap(tester, find.text('Log in'));
}

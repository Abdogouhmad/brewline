// ⚠️  DEBUG-ONLY DUMMY DATA SEEDER — MUST NEVER RUN IN RELEASE BUILDS ⚠️
//
// This file exists so the login flow is testable end-to-end before the real
// staff-management screens are built. It writes throwaway credential records
// into SharedPreferences. It is invoked from `main()` only behind a
// `kDebugMode` guard — do NOT remove that guard, and do NOT call
// `seedDummyAccounts` from production code paths.
//
// Dummy credentials, seeded on first debug run:
//
// | Role  | Username | PIN     | Notes                                                       |
// |-------|----------|---------|-------------------------------------------------------------|
// | Admin | `admin`  | `123456`| Seeded ONLY if no real admin exists yet (never overwrite).  |
// | Waiter| `waiter1`| `111111`| Seeded into the waiter table for the waiter login path.     |
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart'
    show kWaiterAccountsKey;
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart'
    show kAdminPinHashKey, kAdminUsernameKey, kOnboardingCompleteKey;

/// Seeds the debug dummy accounts (see table above).
///
/// - Admin: written only when onboarding has NOT yet run (i.e. before a real
///   admin account exists), so running setup later overwrites the stub and the
///   seeded record never clobbers a real credential.
/// - Waiter: `waiter1` is merged into the waiter accounts map.
///
/// Idempotent — safe to call repeatedly.
Future<void> seedDummyAccounts(SharedPreferences prefs) async {
  if (!kDebugMode) return;

  final onboardingRan = prefs.getBool(kOnboardingCompleteKey) ?? false;
  if (!onboardingRan && prefs.getString(kAdminUsernameKey) == null) {
    await prefs.setString(kAdminUsernameKey, 'admin');
    await prefs.setString(kAdminPinHashKey, hashPin('123456'));
  }

  final waiters = _readWaiters(prefs.getString(kWaiterAccountsKey));
  waiters['waiter1'] = hashPin('111111');
  await prefs.setString(kWaiterAccountsKey, jsonEncode(waiters));
}

Map<String, String> _readWaiters(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return {};
  return decoded.map((key, value) => MapEntry('$key', '$value'));
}

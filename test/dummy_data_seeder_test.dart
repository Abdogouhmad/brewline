import 'dart:convert';

import 'package:brewline/core/dev/dummy_data_seeder.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/features/auth/providers/auth_provider.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('seeder writes dummy admin + waiter on a fresh install', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await seedDummyAccounts(prefs);

    expect(prefs.getString(kAdminUsernameKey), 'admin');
    expect(prefs.getString(kAdminPinHashKey), hashPin('123456'));
    final waiters =
        jsonDecode(prefs.getString(kWaiterAccountsKey)!) as Map<String, dynamic>;
    expect(waiters['waiter1'], hashPin('111111'));
  });

  test('seeder never overwrites a real admin account after onboarding', () async {
    SharedPreferences.setMockInitialValues({
      kOnboardingCompleteKey: true,
      kAdminUsernameKey: 'boss',
      kAdminPinHashKey: hashPin('999999'),
    });
    final prefs = await SharedPreferences.getInstance();

    await seedDummyAccounts(prefs);

    // Real admin left untouched.
    expect(prefs.getString(kAdminUsernameKey), 'boss');
    expect(prefs.getString(kAdminPinHashKey), hashPin('999999'));
  });

  test('seeder is idempotent', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await seedDummyAccounts(prefs);
    await seedDummyAccounts(prefs);

    expect(prefs.getString(kAdminUsernameKey), 'admin');
    final waiters =
        jsonDecode(prefs.getString(kWaiterAccountsKey)!) as Map<String, dynamic>;
    expect(waiters.length, 1);
  });
}

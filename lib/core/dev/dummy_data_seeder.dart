// ⚠️  DEBUG-ONLY DUMMY DATA SEEDER — MUST NEVER RUN IN RELEASE BUILDS ⚠️
//
// This file exists so the login flow and the admin dashboards are testable
// end-to-end before real staff-management / sales data exists. It is invoked
// from `main()` only behind a `kDebugMode` guard — do NOT remove that guard,
// and do NOT call these functions from production code paths.
//
// Dummy credentials, seeded on first debug run:
//
// | Role  | Username | PIN     | Notes                                                    |
// |-------|----------|---------|----------------------------------------------------------|
// | Admin | `admin`  | `1234` | Seeded ONLY if no real admin exists yet (never overwrite).|
// | Waiter| `waiter1`| `1111` | Upserted into the `staff` table.                         |
// | Waiter| `waiter2`| `2222` | Upserted into the `staff` table (staff-tab demo).        |
// | Waiter| `waiter3`| `3333` | Upserted into the `staff` table (staff-tab demo).        |
//
// Additionally, [seedDummyAccounts] fills the order journal with ~3 weeks of
// plausible sample sales (only when the journal is empty) so the Dashboard and
// Reports tabs render real-looking numbers in development. These are
// throwaway records — sales charged through the POS add to the same journal.
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brewline/core/models/order_line_item.dart';
import 'package:brewline/core/models/order_record.dart';
import 'package:brewline/core/models/staff_member.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/core/repositories/staff_repository.dart';
import 'package:brewline/core/security/password_hash.dart';
import 'package:brewline/features/onboarding/providers/onboarding_provider.dart'
    show kAdminPinHashKey, kAdminUsernameKey, kOnboardingCompleteKey;

/// Seeds the debug dummy accounts + sample sales (see notes above).
///
/// Idempotent — safe to call repeatedly.
Future<void> seedDummyAccounts(SharedPreferences prefs, Database db) async {
  if (!kDebugMode) return;

  final onboardingRan = prefs.getBool(kOnboardingCompleteKey) ?? false;
  if (!onboardingRan && prefs.getString(kAdminUsernameKey) == null) {
    await prefs.setString(kAdminUsernameKey, 'admin');
    await prefs.setString(kAdminPinHashKey, hashPin('1234'));
  }

  final staff = StaffRepository(db);
  for (final (username, pin, name) in [
    ('waiter1', '1111', 'Waiter One'),
    ('waiter2', '2222', 'Waiter Two'),
    ('waiter3', '3333', 'Waiter Three'),
  ]) {
    if (await staff.byUsername(username) == null) {
      await staff.upsert(
        StaffMember(
          id: 'staff-$username',
          username: username,
          pinHash: hashPin(pin),
          name: name,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  await seedSampleSales(db);
}

/// Fills the order journal with ~3 weeks of plausible sample sales so the
/// Dashboard and Reports tabs have numbers to chart in development.
///
/// Deterministic (fixed random seed) and skipped when the journal already has
/// orders, so it never duplicates or interferes with real charges.
Future<void> seedSampleSales(Database db) async {
  if (!kDebugMode) return;

  final ordersEmpty =
      (Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM orders'),
          ) ??
          0) ==
      0;
  if (!ordersEmpty) return;

  final products = (await ProductRepository(
    db,
  ).all()).where((p) => p.available).toList();
  if (products.isEmpty) return;

  // Only seed against the untouched default catalog, so edits to products
  // (names/prices) never end up contradicting the sample journal.
  const defaults = {'Espresso', 'Coca-Cola', 'Milk', 'Tea', 'Water'};
  if (products.length != 5 || products.any((p) => !defaults.contains(p.name))) {
    return;
  }

  final random = Random(42);
  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);

  var ticket = 1;
  final batch = db.batch();

  void collect(OrderRecord order) {
    batch.insert('orders', {
      'id': order.id,
      'created_at': order.createdAt.millisecondsSinceEpoch,
      'waiter_username': order.waiterUsername,
      'total': order.total,
    });
    for (final item in order.items) {
      batch.insert('order_items', {
        'order_id': order.id,
        'product_id': item.productId,
        'name': item.name,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
      });
    }
  }

  const waiters = ['waiter1', 'waiter2', 'waiter3'];
  for (var daysAgo = 20; daysAgo >= 0; daysAgo--) {
    final day = dayStart.subtract(Duration(days: daysAgo));
    final isToday = daysAgo == 0;
    final nowHour = now.hour;
    // Fewer orders on today (day not over yet) and a slow Monday variance.
    final orderCount = isToday
        ? (6 + random.nextInt(5))
        : 8 + random.nextInt(11);

    for (var i = 0; i < orderCount; i++) {
      final hour = isToday
          ? min(nowHour, random.nextInt(nowHour + 1))
          : 8 + random.nextInt(16);
      final createdAt = day.add(
        Duration(
          hours: hour,
          minutes: random.nextInt(60),
          seconds: random.nextInt(60),
        ),
      );
      if (createdAt.isAfter(now)) continue;

      final itemCount = 1 + random.nextInt(3);
      final lines = <OrderLineItem>[];
      for (var j = 0; j < itemCount; j++) {
        final product = products[random.nextInt(products.length)];
        lines.add(
          OrderLineItem(
            productId: product.id,
            name: product.name,
            quantity: 1 + random.nextInt(2),
            unitPrice: product.price,
          ),
        );
      }

      collect(
        OrderRecord(
          id: ticket++,
          createdAt: createdAt,
          waiterUsername: waiters[random.nextInt(waiters.length)],
          total: lines.fold<double>(0, (sum, l) => sum + l.total),
          items: lines,
        ),
      );
    }
  }

  await batch.commit(noResult: true);
}

# Brewline CRM — Codebase Audit Report

> **Date:** September 2026  
> **Analyzer:** `flutter analyze` — **No issues found** (clean codebase)  
> **Scope:** All 91 Dart files across `lib/`

---

## Executive Summary

Brewline is a well-structured cross-platform Flutter POS/CRM for coffee stores. The codebase is clean, passes static analysis without warnings, and shows thoughtful design in critical areas (transactional stock deduction, audit trail, money-as-integers). The issues found are mostly **architectural improvements**, **missing safeguards**, and **UX gaps** — not bugs. Priority ratings: 🔴 High | 🟡 Medium | 🟢 Low.

---

## Table of Contents

1. [Architecture & Structure](#1-architecture--structure)
2. [Security](#2-security)
3. [Database Layer (`lib/core/db/`)](#3-database-layer)
4. [Models (`lib/core/models/`)](#4-models)
5. [Repositories (`lib/core/repositories/`)](#5-repositories)
6. [Authentication (`lib/core/auth/`, `lib/features/auth/`)](#6-authentication)
7. [Order & POS Flow (`lib/features/waiter/`)](#7-order--pos-flow)
8. [Admin Dashboard (`lib/features/admin/`)](#8-admin-dashboard)
9. [Printing (`lib/core/printing/`)](#9-printing)
10. [Updates System (`lib/core/updates/`)](#10-updates-system)
11. [Localization (`lib/core/localization/`)](#11-localization)
12. [Shared UI (`lib/shared/`, `lib/widgets/`)](#12-shared-ui)
13. [Configuration (`pubspec.yaml`, `analysis_options.yaml`)](#13-configuration)
14. [Missing Features Summary](#14-missing-features-summary)
15. [Quick-Win Checklist](#15-quick-win-checklist)

---

## 1. Architecture & Structure

### What Is Good ✅
- Clear **feature-first** directory structure (`features/admin`, `features/waiter`, `features/auth`, `features/onboarding`).
- `core/` layer holds platform-agnostic models, repositories, and services.
- Shared UI components in `shared/ui/` and `shared/widgets/` reduce duplication.
- Riverpod used consistently as the state management solution.

### Issues Found

#### 🟡 Inconsistent directory nesting — `lib/widgets/shared/` vs `lib/shared/widgets/`

**Files:** `lib/widgets/shared/`, `lib/shared/widgets/`

**Problem:** Two widget directories exist at different levels:
- `lib/shared/widgets/` — the proper location for truly shared widgets
- `lib/widgets/shared/` — a parallel, inconsistently placed directory containing `auth_screen_layout.dart`, `logout_button.dart`, `order_refund_form.dart`, `refund_action_sheet.dart`

**Why Fix:** Inconsistency makes it harder to find files. A new developer would have to check two locations for shared widgets.

**How to Fix:**
```
Move lib/widgets/shared/* → lib/shared/widgets/
```

---

#### 🟢 `features/admin/settings/widgets/` should be `features/admin/widgets/settings/`

**Files:** `lib/features/admin/settings/widgets/`

**Problem:** The settings sub-widgets (printer, update, etc.) are nested under `settings/widgets/` instead of `widgets/settings/` like the waiter domain does (`lib/features/waiter/widgets/settings/`).

**How to Fix:** Rename to match the waiter convention for consistency.

---

## 2. Security

#### 🔴 Unsalted SHA-256 PIN hashing

**File:** `lib/core/security/password_hash.dart`

```dart
// Current implementation — line 11
String hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();
```

**Problem:** PINs are hashed without a per-user salt. This means:
1. Any two users with the same PIN produce the **identical** hash in the database.
2. A leaked database allows rainbow-table attacks against 4-digit PINs (only 10,000 possibilities).
3. The code itself acknowledges this in the docstring as a known limitation.

**Why Fix:** 4-digit PINs are brute-forceable in milliseconds without salting. If the database file is ever exfiltrated (backup, file share), all PINs are compromised.

**How to Fix:**
```dart
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Returns a cryptographically random salt (hex-encoded).
String generateSalt() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Hash a PIN with a given salt.
String hashPin(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();
```

Store the salt alongside the hash (e.g., `pin_salt` column in `staff`, and a separate `kAdminPinSaltKey` in SharedPreferences).

**Value Added:** Eliminates rainbow-table attacks; even if two users pick the same PIN their stored hashes differ.

---

#### 🟡 Admin credentials stored in SharedPreferences (plaintext-accessible)

**Files:** `lib/features/onboarding/providers/onboarding_provider.dart`, `lib/core/auth/pin_lookup.dart`

**Problem:** The admin username (`kAdminUsernameKey`) and PIN hash (`kAdminPinHashKey`) are stored in SharedPreferences. On Android, SharedPreferences writes to an XML file in the app's data directory — accessible without root on developer builds and via ADB backups.

**How to Fix:** Use `flutter_secure_storage` for credential keys on mobile platforms, falling back to SharedPreferences only on desktop (where there is no equivalent keychain).

**Value Added:** Protects admin credentials from being trivially extracted during a device backup or developer mode session.

---

#### 🟡 No brute-force protection on PIN entry

**File:** `lib/features/auth/providers/auth_provider.dart`

**Problem:** The `login()` method has no rate limiting, attempt counter, or lockout. A bad actor with physical access to the device could try all 10,000 4-digit PINs programmatically.

**How to Fix:**
```dart
// Track failed attempts in SharedPreferences
static const int _maxAttempts = 5;
static const Duration _lockoutDuration = Duration(minutes: 5);
```
Implement a lockout after N consecutive failures; persist the count and lockout timestamp in SharedPreferences.

**Value Added:** Makes credential brute-forcing impractical even with direct device access.

---

#### 🔴 Staff ID generated from timestamp — collision risk

**File:** `lib/features/admin/widgets/staff_form_sheet.dart` (line 97)

```dart
id: member?.id ?? 'staff-${DateTime.now().millisecondsSinceEpoch}',
```

**Problem:** If two staff members are added within the same millisecond (e.g., rapid automated testing, or a copy-paste bug), they get the same primary key, causing a SQLite `UNIQUE` constraint violation. Same pattern in `product_form_sheet.dart`.

**How to Fix:** Use a UUID package (`package:uuid`) or a cryptographically random hex ID:
```dart
import 'dart:math';
String _generateId() {
  final rng = Random.secure();
  return 'staff-${rng.nextInt(0xFFFFFFFF).toRadixString(16)}';
}
```

**Value Added:** Eliminates the rare but possible ID collision crash.

---

## 3. Database Layer

**File:** `lib/core/db/app_database.dart`

### What Is Good ✅
- Schema migrations are well-documented with a version history table.
- `PRAGMA foreign_keys = ON` is correctly set in `onConfigure`.
- Indexes are defined for every join used in dashboard queries.
- Money stored as integer cents for cashouts and refunds avoids floating-point drift.
- Duplicate index definitions between `kMigrations` and `_kIndexes` are handled gracefully with `CREATE INDEX IF NOT EXISTS`.

### Issues Found

#### 🟡 `products.price` and `orders.total` use `REAL` — floating-point storage

**File:** `lib/core/db/app_database.dart` (lines 304, 318)

```sql
price REAL NOT NULL,   -- products table
total REAL NOT NULL,   -- orders table
```

**Problem:** The codebase correctly stores money as integers for cashouts (`total_sales_cents`, `cash_counted_cents`) and refunds (`amount_cents`), but product prices and order totals use `REAL`. SQLite `REAL` is an IEEE 754 float — it can represent `9.00` as `8.999999999...`. This inconsistency means revenue aggregates may silently accumulate floating-point rounding errors.

**How to Fix:** Add a migration (version 6) to rename `price` → `price_cents` (`price * 100`) and `total` → `total_cents`. Update all display code to divide by 100.

**Value Added:** Consistent integer math across the entire money pipeline. No accumulation of rounding error in daily revenue totals.

---

#### 🟡 `_onUpgrade` relies on implicit Map insertion order

**File:** `lib/core/db/app_database.dart` (lines 287-294)

```dart
for (final version in kMigrations.keys) {
  if (version > oldVersion && version <= newVersion) {
```

**Problem:** `kMigrations` is a `const Map<int, List<String>>`. Dart `Map` preserves insertion order, and the migrations happen to be inserted in order (2, 3, 4, 5). But this is an implicit assumption. If a developer adds a future migration out of order, the upgrade would apply in wrong sequence.

**How to Fix:**
```dart
final versions = kMigrations.keys.toList()..sort();
for (final version in versions) {
```

**Value Added:** Prevents subtle migration ordering bugs as the schema grows.

---

#### 🟢 `deleteAllData` does not use a transaction

**File:** `lib/core/db/app_database.dart` (lines 500-512)

```dart
Future<void> deleteAllData(Database db) async {
  await db.delete('stock_movements');
  await db.delete('product_recipes');
  // ... 8 more individual deletes
}
```

**Problem:** If the app crashes mid-delete (during "Reset business data"), the database could be left in a half-wiped state.

**How to Fix:**
```dart
Future<void> deleteAllData(Database db) async {
  await db.transaction((txn) async {
    for (final table in ['stock_movements', 'product_recipes', 'ingredients',
        'order_refunds', 'order_items', 'orders', 'order_counters',
        'audit_events', 'cashout_logs', 'staff', 'products']) {
      await txn.delete(table);
    }
  });
}
```

**Value Added:** Atomic wipe — either everything is deleted or nothing is, no partial states.

---

## 4. Models

**Directory:** `lib/core/models/`

### What Is Good ✅
- All models are immutable value types.
- `toRow()` / `fromRow()` pattern for SQLite serialization is consistent.
- `Product.isLowStock` computed property avoids duplicating threshold logic.

### Issues Found

#### 🟡 `Product`, `StaffMember`, `Ingredient` missing `copyWith`

**Files:** `lib/core/models/product.dart`, `lib/core/models/staff_member.dart`, `lib/core/models/ingredient.dart`

**Problem:** Without `copyWith`, developers must construct the entire object to change one field — error-prone and verbose.

**How to Fix (Product example):**
```dart
Product copyWith({
  String? id, String? name, double? price, String? imagePath,
  String? category, bool? available, int? stockQuantity,
  int? lowStockThreshold, bool? isArchived,
}) => Product(
  id: id ?? this.id,
  name: name ?? this.name,
  price: price ?? this.price,
  imagePath: imagePath ?? this.imagePath,
  category: category ?? this.category,
  available: available ?? this.available,
  stockQuantity: stockQuantity ?? this.stockQuantity,
  lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
  isArchived: isArchived ?? this.isArchived,
);
```

**Value Added:** Cleaner update logic; reduces risk of forgetting a field when constructing a modified copy.

---

#### 🟢 No `==` or `hashCode` override on models

**Files:** All files in `lib/core/models/`

**Problem:** Models don't implement value equality. Two `Product` objects with identical fields are not equal (`==`), so they can't be used in `Set`s or compared in tests without field-by-field checks.

**How to Fix:** Use `package:equatable` or `package:freezed` for automatic `==`, `hashCode`, and `copyWith` generation.

---

## 5. Repositories

**Directory:** `lib/core/repositories/`

### What Is Good ✅
- Repository pattern cleanly applied — UI never touches `Database` directly.
- `OrderJournalRepository.addOrder()` deducts ingredient stock **inside the same transaction** as order insertion — correct atomicity.
- `SalesQueryRepository` is correctly separated as read-only.
- Low-stock query (`lowStock()`) filters in SQL, not Dart — good performance.

### Issues Found

#### 🔴 `ProductRepository.upsert` has a TOCTOU race condition and unnecessary complexity

**File:** `lib/core/repositories/product_repository.dart` (lines 95-111)

```dart
Future<void> upsert(Product product) async {
  final existing = await byId(product.id); // SELECT
  if (existing == null) {
    await _db.insert('products', ...,
      conflictAlgorithm: ConflictAlgorithm.replace,  // already handles conflict!
    );
  } else {
    await _db.update('products', ...);
  }
}
```

**Problem:** Between the `SELECT` and the `INSERT`/`UPDATE`, another write could arrive. More importantly, the `insert` already uses `ConflictAlgorithm.replace`, making the `SELECT` branch entirely redundant.

**How to Fix:**
```dart
Future<void> upsert(Product product) async {
  await _db.insert(
    'products',
    product.toRow(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
```

**Value Added:** Simpler, faster (one DB call instead of two), and thread-safe.

---

#### 🟡 `OrderJournalRepository._tzOffsetMs` is a static field — doesn't update with timezone changes

**File:** `lib/core/repositories/order_journal_repository.dart` (line 115)

```dart
static final int _tzOffsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
```

**Problem:** This captures the timezone offset when the class is first loaded. If the device's timezone changes while the app is running (e.g., DST transition), day-bucketing for revenue charts will be wrong.

**How to Fix:**
```dart
static int get _tzOffsetMs => DateTime.now().timeZoneOffset.inMilliseconds;
```

**Value Added:** Day-boundary calculations stay accurate even across DST transitions.

---

#### 🟡 `SalesQueryRepository.getSales` does not validate `offset` / `limit`

**File:** `lib/core/repositories/sales_query_repository.dart` (lines 156-163)

**Problem:** Negative `limit` or `offset` values would produce invalid SQL with no guard.

**How to Fix:**
```dart
assert(limit > 0, 'limit must be positive');
assert(offset >= 0, 'offset must be non-negative');
```

---

## 6. Authentication

**Files:** `lib/core/auth/pin_lookup.dart`, `lib/features/auth/providers/auth_provider.dart`

### What Is Good ✅
- PIN lookup correctly checks admin (SharedPreferences) then staff (SQLite).
- `isPinTaken` correctly excludes the user's own existing PIN during edits.
- `AuthException` uses a deliberately generic message to avoid leaking credential details.
- Login/logout events are written to `audit_events`.

### Issues Found

#### 🟡 `pinLookupProvider` returns a `Future Function(String)` — awkward Riverpod pattern

**File:** `lib/core/auth/pin_lookup.dart` (lines 122-130)

```dart
final pinLookupProvider = Provider<Future<PinLookupResult?> Function(String)>(
```

**Problem:** Returning a function from a provider is an unusual pattern in Riverpod. It makes the provider harder to test and the type is verbose.

**How to Fix:** Inject dependencies directly into `AuthNotifier` via `ref.read` on the sub-providers it needs, removing the function wrapper entirely.

---

#### 🟡 `OnboardingPage` and `LoginPage` use `addPostFrameCallback` for navigation — can fire multiple times

**Files:** `lib/features/onboarding/pages/onboarding_page.dart`, `lib/features/auth/login_page.dart`

```dart
if (complete) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) Navigator.of(context).pushReplacement(...);
  });
}
```

**Problem:** Scheduling navigation in `build()` via `addPostFrameCallback` can fire multiple times if the widget rebuilds while the frame is pending.

**How to Fix:** Use `ref.listen` to react to state changes exactly once:
```dart
ref.listen(onboardingCompleteProvider, (_, complete) {
  if (complete && context.mounted) {
    Navigator.of(context).pushReplacement(...);
  }
});
```

**Value Added:** More robust navigation; prevents rare double-navigation bugs.

---

## 7. Order & POS Flow

**Directory:** `lib/features/waiter/`

### What Is Good ✅
- `OrderController.charge()` correctly persists, decrements product stock, and bumps mutation counters atomically.
- Print receipts fire **after** the charge completes and are fire-and-forget — a dead printer never blocks a sale.
- `OrderItem.totalPrice` stays in sync with the product price at the time of order.

### Issues Found

#### 🔴 No undo or confirmation before clearing order

**File:** `lib/features/waiter/pages/orders_page.dart` (lines 41-49)

```dart
void clear() {
  order.clear(); // immediate, no confirmation
  showUiSnackBar(context, 'Order cleared', ...);
}
```

**Problem:** Tapping "Clear order" immediately destroys the current cart with no undo. On a busy shift, an accidental tap loses the entire order.

**How to Fix:** Make the snackbar action an **undo** that restores cart items:
```dart
void clear() {
  final backup = [...ref.read(orderControllerProvider)];
  order.clear();
  showUiSnackBar(
    context, 'Order cleared',
    label: 'Undo',
    onLabelPressed: () => ref.read(orderControllerProvider.notifier).restore(backup),
  );
}
```

**Value Added:** Recovers from accidental taps without losing a table's order during a busy service.

---

#### 🟡 `OrderController.charge()` silently continues when `auth` is null

**File:** `lib/features/waiter/providers/order_provider.dart` (lines 91-97)

```dart
final auth = ref.read(authProvider).value;
// ...
waiterUsername: auth?.username, // null-safe but silently unattributed
```

**Problem:** If the session is somehow null, the order is saved without a waiter attribution and no error is shown to the user.

**How to Fix:**
```dart
final auth = ref.read(authProvider).value;
if (auth == null) {
  _log('Charge aborted: no active session');
  return;
}
```

**Value Added:** Prevents orders being saved with no waiter attribution, which breaks sales-by-waiter reports.

---

#### 🟡 `price_format.dart` is in `features/waiter/providers/` but imported across the entire app

**File:** `lib/features/waiter/providers/price_format.dart`

**Problem:** `formatPrice()` and `kCurrencySymbol` are imported from a waiter-domain file into admin pages, dashboard widgets, and receipt templates. A cross-cutting utility shouldn't live in a feature subdomain.

**How to Fix:** Move to `lib/core/utils/price_format.dart`.

**Value Added:** Cleaner dependency graph; admin code no longer depends on waiter code.

---

#### 🟢 `OrderItem` model lives inside `order_provider.dart` — should be its own file

**File:** `lib/features/waiter/providers/order_provider.dart` (lines 19-30)

**Problem:** `OrderItem` is a model class co-located with provider logic. Models should be in `lib/core/models/`.

---

## 8. Admin Dashboard

**Directory:** `lib/features/admin/`

### What Is Good ✅
- Dashboard KPIs are derived from SQL aggregates — no duplication.
- `_KpiGrid` adapts columns by breakpoint (2 → 3 → 4).
- `SalesLogPage` uses manual pagination ("Load more") — bounded memory.
- Cashout log correctly records counted cash + variance at close time.
- Refund badges clearly distinguish voided vs. partially refunded orders.
- Ingredient stock deduction runs in the same transaction as order insertion.

### Issues Found

#### 🔴 "Reset business data" has only one confirmation — no friction for a destructive action

**File:** `lib/features/admin/pages/admin_settings_page.dart` (lines 128-172)

**Problem:** A single "Reset" button in the confirmation dialog can destroy all business data. There is no second factor, no typed confirmation, and no backup offered.

**How to Fix:** Require the admin to type "RESET" in a text field before the button activates:
```dart
final controller = TextEditingController();
// Show button only when controller.text == 'RESET'
```

**Value Added:** Eliminates accidental or UI-glitch-triggered data loss.

---

#### 🟡 Cashout logs table missing cash variance column

**File:** `lib/features/admin/pages/cashout_logs_page.dart` (lines 310-315)

```dart
columns: const [
  DataColumn(label: Text('Date & Time')),
  DataColumn(label: Text('Orders Made')),
  DataColumn(label: Text('Waiter Name')),
  DataColumn(label: Text('Total Made')),
  // Missing: Cash Counted, Variance
],
```

**Problem:** `cash_counted_cents` and `cash_variance_cents` are stored in the database but never shown. The variance is the most useful column for detecting discrepancies.

**How to Fix:** Add `Cash Counted` and `Variance` columns; highlight negative variance in red using `colorScheme.error`.

**Value Added:** Surfaces cash discrepancies at a glance — the main reason the cashout log exists.

---

#### 🟡 `SalesLogPage` `_load(reset: true)` sets `_hasMore = true` before the query resolves

**File:** `lib/features/admin/pages/sales_log_page.dart` (lines 62-72)

**Problem:** If a filter change returns 0 results, `_hasMore` stays `true` until the query resolves, causing a brief flash of the "Load more" button.

**How to Fix:** Remove `_hasMore = true` from the reset block — let it be determined solely by the result length.

---

#### 🟡 `_DateFilterInput` widget duplicated across `sales_log_page.dart` and `cashout_logs_page.dart`

**Problem:** Nearly identical code in both files. Any bug fix has to be applied twice.

**How to Fix:** Extract to `lib/shared/widgets/date_filter_input.dart` with a `showTodayButton` parameter.

**Value Added:** One fix, one test, consistent behavior across both log pages.

---

#### 🟢 `_months` constant duplicated in both log pages

**Problem:** `const List<String> _months = ['Jan', 'Feb', ...]` is copy-pasted in two files.

**How to Fix:** Extract to `lib/core/utils/date_format.dart` alongside a shared `formatDate()` function.

---

#### 🟡 `InventoryPage` `onEdit` does a redundant `byId` database call

**File:** `lib/features/admin/pages/inventory_page.dart` (lines 120-131)

```dart
final history = await repo.byId(ingredient.id); // ingredient already in hand!
```

**Problem:** The ingredient object is already available from the list. `byId` is called to check if `history != null`, but the ingredient is clearly in the list and therefore exists.

**How to Fix:** Remove the `byId` call and pass the `ingredient` object directly to `showIngredientFormSheet`.

---

#### 🟢 Magic breakpoint number `600` used instead of `Breakpoints` class

**File:** `lib/features/admin/pages/admin_dashboard_page.dart` (line 58)

```dart
MediaQuery.of(context).size.width < 600 ? Space.lg : Space.full
```

**How to Fix:**
```dart
Breakpoints.of(context) == ScreenSize.compact ? Space.lg : Space.full
```

Same issue appears in `sales_log_page.dart` and `cashout_logs_page.dart`.

---

## 9. Printing

**Directory:** `lib/core/printing/`

### What Is Good ✅
- Transport-agnostic design (network socket vs. USB plugin) is excellent.
- Print failures are typed (`PrinterException`) and never bubble into the charge flow.
- The shift report correctly prints only after `logCashout()` succeeds — ledger integrity guaranteed.

### Issues Found

#### 🟡 `ReceiptPrinterService._transport()` creates a new TCP connection per print job

**File:** `lib/core/printing/receipt_printer_service.dart` (lines 46-49)

```dart
PrinterTransport _transport() => settings.connectionType == ...
    ? NetworkPrinterTransport(host: settings.ipAddress, port: settings.port)
    : const UsbPrinterTransport();
```

**Problem:** For network printing, a new `NetworkPrinterTransport` is created for every call. If a kitchen ticket and client receipt are both printed for the same order, two separate TCP connections are opened sequentially, adding latency.

**How to Fix:** Reuse the transport within a single print batch:
```dart
Future<void> _printAll(List<Future<void> Function(PrinterTransport)> jobs) async {
  final transport = _transport();
  for (final job in jobs) await job(transport);
}
```

**Value Added:** Halves the TCP handshake overhead when both receipts are enabled.

---

## 10. Updates System

**Directory:** `lib/core/updates/`

### What Is Good ✅
- GitHub Releases API is the single source of truth — no separate manifest JSON.
- Failed update checks are silent — never block startup.
- Mandatory updates take over the entire app via `UpdateAppGate`.

### Issues Found

#### 🟡 Failed update checks are completely silent — no admin feedback

**File:** `lib/core/updates/update_service.dart` (line 27)

**Problem:** If the GitHub repo is renamed, the network is offline, or the rate limit is hit, `fetchLatestRelease()` returns `null` with no feedback. The admin sees no indication that update checks are failing.

**How to Fix:** Expose a "Last check" timestamp and status ("Failed", "Up to date", "Update available") in Settings → Updates, so the admin can distinguish "never checked" from "check failed".

**Value Added:** Gives the admin visibility into whether automatic updates are actually working.

---

#### 🟢 `installerForCurrentPlatform()` throws `UnsupportedError` on macOS/iOS

**File:** `lib/core/updates/update_service.dart` (lines 59-67)

**Problem:** If ever compiled for macOS or iOS, calling `check()` will throw an unhandled `UnsupportedError` at runtime.

**How to Fix:** Catch the `UnsupportedError` in the update provider, or guard with a platform check before calling `check()`.

---

## 11. Localization

**File:** `lib/core/localization/locale_controller.dart`

### Issues Found

#### 🔴 `localeProvider` is computed but never wired into `MaterialApp`

**File:** `lib/core/localization/locale_controller.dart` (lines 24-25)

```dart
// TODO: wire localeProvider into `MaterialApp` once .arb
// localizations land; for now the choice is only persisted.
```

**Problem:** The language dropdown in Settings is visible and interactive, but selecting "Arabic" or "English" has **zero visual effect** on the app. Users see a non-functional control.

**How to Fix (Option A — quick):** Hide the language dropdown from Settings until localization is implemented. Add a comment or "Coming soon" label.

**How to Fix (Option B — proper):** Wire `localeProvider` into `MaterialApp`:
```dart
locale: ref.watch(localeProvider),
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```
And add `.arb` files for English and Arabic.

**Value Added:** If Option B, the app becomes accessible to Arabic-speaking staff (RTL support). The currency `DH` (Moroccan Dirham) strongly suggests a North African market where Arabic support is commercially important. If Option A, it removes misleading UI that creates user confusion.

---

## 12. Shared UI

**Directory:** `lib/shared/`, `lib/widgets/`

### What Is Good ✅
- `UiButton`, `UiCard`, `UiText`, `UiSnackBar` create a consistent design vocabulary.
- `UiAdaptiveModal` correctly uses bottom sheet on mobile and dialog on desktop.
- `ResponsiveGrid` and `Breakpoints` provide a consistent layout system.

### Issues Found

#### 🟡 `OrderRefundForm._confirmButton` has a dead conditional — both branches identical

**File:** `lib/widgets/shared/order_refund_form.dart` (lines 396-404)

```dart
variant: _mode == _RefundMode.voidOrder
    ? UiButtonVariant.filled   // same!
    : UiButtonVariant.filled,  // same!
```

**Problem:** The conditional does nothing. The void mode should use a destructive style to signal higher risk than a partial refund.

**How to Fix:** Add a `UiButtonVariant.destructive` that applies `error` colors, or use `FilledButton.styleFrom(backgroundColor: colorScheme.error)` directly for the void case.

**Value Added:** Visual differentiation between "partial refund" (normal action) and "void entire order" (destructive action), reducing mis-taps.

---

#### 🟢 `staff_table.dart` uses hard-coded `Colors.green.shade600` — not theme-aware

**File:** `lib/features/admin/widgets/staff_table.dart` (lines 186-188)

```dart
Color _activeDotColor(BuildContext context, bool active) => active
    ? Colors.green.shade600  // not from colorScheme
    : Theme.of(context).colorScheme.outlineVariant;
```

**Problem:** Hard-coded green doesn't adapt to dark mode or Material You palettes. In dark mode it may fail WCAG contrast requirements.

**How to Fix:** Use `colorScheme.primary` or `colorScheme.tertiary` for the active dot.

---

#### 🟢 `staff_form_sheet.dart` — PIN fallback logic is fragile when `member` is null

**File:** `lib/features/admin/widgets/staff_form_sheet.dart` (lines 99-101)

```dart
pinHash: newPin.isEmpty
    ? (member?.pinHash ?? hashPin(newPin))  // hashPin('') if no member!
    : hashPin(newPin),
```

**Problem:** If `member` is null AND `newPin` is empty, the fallback `hashPin('')` hashes an empty string — logically incorrect even though the validator blocks it in practice.

**How to Fix:**
```dart
pinHash: newPin.isNotEmpty ? hashPin(newPin) : member!.pinHash,
```

---

## 13. Configuration

**Files:** `pubspec.yaml`, `analysis_options.yaml`

### Issues Found

#### 🟡 `dynamic_color: 1.9.0` uses exact pinning — prevents minor bugfix updates

**File:** `pubspec.yaml` (line 40)

```yaml
dynamic_color: 1.9.0   # exact pin — no ^
```

**Problem:** Exact version pinning means `flutter pub upgrade` can never get a bugfix release for this dependency.

**How to Fix:** Use `^1.9.0` unless there is a known breaking change in later patch versions.

---

#### 🟢 No lint rules beyond `flutter_lints` defaults

**File:** `analysis_options.yaml`

**Problem:** `flutter_lints` is the minimum baseline. Consider adding stricter rules to catch more issues at compile time.

**How to Fix:** Add to `analysis_options.yaml`:
```yaml
linter:
  rules:
    prefer_final_fields: true
    avoid_dynamic_calls: true
    require_trailing_commas: true
    prefer_const_constructors: true
    sort_constructors_first: true
```

---

#### 🔴 Zero test coverage

**Problem:** There are zero test files in the repository. A POS system handling real money should have at minimum unit and integration tests.

**Why Fix:** Without tests, refactoring the database schema, repositories, or auth flow risks silent regressions. A bug in `addOrder` could cause orders to silently fail to be written, stock to not be deducted, or order numbers to collide.

**How to Fix:** Add a `test/` directory:
```
test/
  unit/
    password_hash_test.dart
    price_format_test.dart
    product_model_test.dart
  repository/
    order_journal_repository_test.dart
    product_repository_test.dart
    cashout_repository_test.dart
```

Use `openAppDatabase(path: ':memory:')` (already supported) for in-memory repository tests.

**Value Added:** Confidence during refactoring, catch regressions early, document expected behavior.

---

## 14. Missing Features Summary

| Feature | Priority | Notes |
|---|---|---|
| Arabic/RTL localization | 🔴 | Language pref stored but UI not wired |
| PIN salting | 🔴 | SHA-256 unsalted is weak for 4-digit PINs |
| Unit + integration tests | 🔴 | Zero test coverage on money-handling code |
| Brute-force lockout on login | 🟡 | No attempt counter exists |
| Payment flow (cash/card split) | 🟡 | `charge()` has `TODO: real payment flow` comment |
| CSV/PDF export for sales log | 🟡 | Admin can't export data |
| Cashout variance in logs table | 🟡 | `cash_variance_cents` stored but not displayed |
| Undo "Clear order" | 🟡 | One tap destroys entire cart |
| `copyWith` on models | 🟢 | Missing on `Product`, `StaffMember`, `Ingredient` |
| Category management UI | 🟢 | Categories are free-text — no canonical list |
| Unarchive product/ingredient | 🟢 | Soft-delete exists but no restore path in UI |
| Value equality (`==`) on models | 🟢 | Cannot compare models or use in `Set` |

---

## 15. Quick-Win Checklist

These can each be fixed in under 1 hour:

- [ ] 🔴 Fix `_confirmButton` dead conditional in `order_refund_form.dart` (same variant both branches)
- [ ] 🔴 Fix migration key sorting: `kMigrations.keys.toList()..sort()`
- [ ] 🔴 Replace `PostFrameCallback` navigation with `ref.listen` in `LoginPage` and `OnboardingPage`
- [ ] 🔴 Add zero test files → at minimum `password_hash_test.dart` and `price_format_test.dart`
- [ ] 🟡 Simplify `ProductRepository.upsert` — remove the redundant `byId` pre-check
- [ ] 🟡 Fix `_tzOffsetMs` static field → make it a getter in `OrderJournalRepository`
- [ ] 🟡 Move `price_format.dart` to `lib/core/utils/price_format.dart`
- [ ] 🟡 Extract shared `_DateFilterInput` and `_months` to `lib/shared/widgets/`
- [ ] 🟡 Add cash counted + variance columns to cashout logs table
- [ ] 🟡 Replace `Colors.green.shade600` with `colorScheme.primary` in `staff_table.dart`
- [ ] 🟡 Replace magic `600` breakpoint number with `Breakpoints.of(context)` (3 files)
- [ ] 🟡 Wrap `deleteAllData` in a single transaction
- [ ] 🟡 Remove or stub-out the language dropdown (it does nothing currently)
- [ ] 🟡 Add "type RESET to confirm" safeguard to data reset dialog
- [ ] 🟡 Add `cash_variance_cents` guard: show it in red when negative in cashout table
- [ ] 🟢 Add `copyWith` to `Product`, `StaffMember`, `Ingredient`
- [ ] 🟢 Fix the `pinHash` fallback logic in `staff_form_sheet.dart`
- [ ] 🟢 Move `lib/widgets/shared/` contents into `lib/shared/widgets/`

---

*Report generated by codebase audit — September 2026. Static analysis: `flutter analyze` clean (0 issues). Priority: 🔴 High | 🟡 Medium | 🟢 Low.*

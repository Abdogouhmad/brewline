# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-09-01

### Added (cross-platform OTA updates)

- **In-app OTA update system** for Android, Windows and Linux (`core/updates/`):
  - `UpdateService` fetches a single multi-platform JSON manifest
    (`update.json`) hosted on GitHub and picks the section matching the
    device — Android compares integer `versionCode`, Windows/Linux compare
    semantic versions via `pub_semver`.
  - `UpdateInstaller` abstraction (mirroring the existing `PrinterTransport`
    pattern): one interface, one implementation per platform
    (`AndroidUpdateInstaller` downloads + validates the APK then hands off to
    the system package installer; `DesktopUpdateInstaller` downloads the
    platform archive, verifies its SHA-256, extracts to a **fresh versioned
    directory** — never overwriting the running app — and relaunches).
  - `UpdateNotifier` Riverpod state machine:
    `idle → checking → available / downloading(progress) → readyToInstall → error`,
    plus an auto-check on launch (default on, toggleable in Settings) and a
    persisted "last checked" timestamp.
- **Admin Settings → Update card** (`update_section.dart`): current version +
    platform label, "Check for updates", auto-check toggle and last-checked
    time.
- **Waiter Settings → Update card** — the same OTA card is now a universal
    feature, shown on both the admin and waiter settings pages.
- **Admin Settings desktop grid** (`admin_settings_page.dart`) — the section
    cards now lay out in a 2-column responsive grid on desktop (≥ 905dp);
    General spans the full first row while Printer, Update and Account pair
    two-per-row. Phones/tablets keep the stacked layout. Content cap widened
    from 600 to 1200dp so wide screens use the space.
- **Responsive update action sheet** (`update_action_sheet.dart`) — reuses the
    existing `showUiAdaptiveModal` shell, so it renders as a centred dialog on
    desktop and a bottom sheet on phones with no platform branching.
- **Mandatory-update takeover** (`update_required_screen.dart`): a
    non-dismissible, full-screen gate (`UpdateAppGate` in `main.dart`) that
    blocks the entire app until the mandatory update is installed, on every
    platform.
- **SHA-256 verification** before anything is installed — a mismatched
    download is deleted and reported, never applied.
- **CI manifest generation**: the `release` workflow now hashes all three
    artifacts (APK, Windows zip, Linux tar.gz) and commits the updated
    `update.json` back to `main` so the raw GitHub URL always serves the
    current release.

[Unreleased]: https://github.com/Abdogouhmad/brewline/compare/1.3.0...HEAD
[1.3.0]: https://github.com/Abdogouhmad/brewline/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/Abdogouhmad/brewline/compare/1.2.0...1.2.1

## [1.2.1] - 2026-08-30

### Fixed

- **Android release builds can now print over the network.** The `INTERNET`
  permission was only declared in the debug/profile manifests, so release APKs
  installed on a phone had no network access and TCP printing to a networked
  ESC/POS printer (e.g. the escpresso emulator on port 9100) silently failed.
  Moved the permission into the main manifest so it ships in release builds.

## [1.2.0] - 2026-08-30

### Added (cashout & report printing)

- **Printer support** (`core/printing/`) — the app's first printing layer:
  - `ReceiptPrinterService` resolves the transport per print call: a raw TCP
    socket to the printer's port 9100 (all platforms) or USB via
    `flutter_pos_printer_platform_image_3` (Android/Windows; throws a clear
    offline error elsewhere). Typed `PrinterOfflineException` /
    `PrinterTimeoutException` with a 5s socket timeout and a best-effort
    teardown that never masks the real error.
  - Admin Settings gains a **Printer** card (`printer_settings_section.dart`):
    USB/Network toggle + IP/port, persisted through SharedPreferences and
    applied on the next print without a restart.
  - Receipt templates on the `esc_pos_utils_plus` byte builder: **55mm kitchen
    ticket**, **88mm client receipt** and the **shift report**, with a shared
    `posText` helper that strips characters the Latin-1 ESC/POS code page can't
    encode so a non-ASCII string can never crash a receipt. Line widths are
    measured against the SHK-165 preset and flagged in doc comments to
    double-check against other printer hardware.
- **Cashout ledger** — database v3 (`kDatabaseVersion = 3`): new `cashout_logs`
  table (waiter snapshot, gross/tax/discounts/counted-cash, totals stored as
  integer cents, integer-ms epochs, FK to `staff`). `CashoutRepository` exposes
  the single write path — `logCashout` writes exactly one ledger row plus one
  `cashout` audit event in one transaction (atomic; a failed insert leaves no
  partial close) — and `currentShiftSummary` derives the shift window from the
  latest login (falling back to start-of-day) and tallies its orders.
- **Waiter Settings → Cash out & print** (`cashout_button.dart`): confirm →
  cash-counted prompt (pre-filled with the expected float) → ledger row +
  audit event → final report print → logout to the login screen. A printer
  failure never blocks the cashout — it shows an inline retry instead.
- **Waiter Settings → Print report** (`print_report_button.dart`): interim,
  non-destructive print prefixed with a loud `PREVIEW - SHIFT NOT CLOSED`
  banner, recorded as a `report_print` audit event; the shift stays open.
- **Admin → Cashout Logs** (`cashout_logs_page.dart`): date-range + waiter
  filters over a `DataTable` (Date & Time / Orders Made / Waiter Name /
  Total Made), newest first with 100-per-page "Load more" pagination.
- **Charge-flow printing** (`order_provider.dart`): a successful charge now
  prints the kitchen + client receipts automatically (fire-and-forget, never
  blocks the sale), honouring the per-receipt toggles.

### Changed

- `audit_events` CHECK constraint (v3 and `_createSchema`) and
  `AuditRepository.kEventTypes` now also accept `report_print` and
  `password_changed` events.

### Fixed

- Cashouts no longer crash on write: `CashoutRecord.toRow()` now persists the
  `waiter_username` column (previously missing against the NOT NULL
  constraint).
- Pre-existing: changing a waiter PIN crashed on the rejected
  `password_changed` audit event; the events CHECK now permits it.

### Tests

- `cashout_repository_test.dart`, `network_printer_transport_test.dart` (against
  a real loopback TCP server: exact bytes, offline + 16 MB unread-timeout
  cases), `receipt_templates_test.dart`, plus migration v3 and audit
  `report_print`/`password_changed` coverage — 67 tests passing
  (`flutter analyze` clean).

## [1.1.1] - 2026-08-30

### Added (admin dashboard v2 — schema, sales log, images, responsive)

- **Database v2** (`core/db/app_database.dart`) — `kDatabaseVersion = 2` with a
  documented migration history (`_kMigrationDescriptions`) and an
  `onUpgrade` that replays `kMigrations`; fresh installs build the full v2
  schema directly. Adds:
  - `orders.order_number` + `order_counters` table — per-day sequential ticket
    numbers handed out atomically inside `addOrder` (SELECT … FOR UPDATE-style
    transaction, not `MAX()+1`), resetting daily; `0` stays "unassigned" for
    seeded/historical rows.
  - `products.is_archived` soft delete — archived products leave historical
    order/order_item integrity intact and drop out of the live catalog.
  - `audit_events` table (`event_type TEXT CHECK … login/logout/cashout`,
    `actor`, `metadata` JSON) — login, logout and cashout are now recorded;
    cashout is written from the waiter Settings with gross/order-count payload.
  - Indexes for the hot paths: `orders.created_at`, `orders.waiter_username`,
    `order_items.order_id`, `products.is_available`, `audit_events.actor`.
- **Sales Log tab** (`SalesLogPage` + `sales_query_repository.dart`) — a query
  over `orders`/`order_items`/`products`, not a new table: filterable
  (date range, product, waiter) `DataTable` of ticket, date, items, revenue and
  waiter, backed by `getSales()` over indexed joins.
- **Order numbers end to end** — ticket numbers surface on the waiter checkout
  and sales log; `nextOrderNumberForDay` keeps daily continuity across
  restarts.
- **Product gallery images** — `image_picker` (gallery) + `path_provider`
  (document-dir storage) roundtrip: picked photos are copied into the app's
  documents folder (`product_images/`) so they persist across restarts;
  `ProductImage` widget renders asset/images/files with a graceful fallback;
  the product form shows a live preview before saving.
- **Responsive overhaul** — `core/responsive/breakpoints.dart` +
  `responsive_text.dart` are now the canonical responsive utilities (see §8):
  - `AppShell` 3-tier navigation: bottom `NavigationBar` (≤ 3 destinations + a
    working "More" sheet) on compact, `NavigationRail` on medium, permanent
    `NavigationDrawer` sidebar on expanded — used by both the admin and waiter
    profiles.
  - Dashboard cards shrink on mobile/tablet and keep their desktop footprint
    (`kpi_card.dart` heights 132/140 + clamped label typography); dashboard
    labels/numbers no longer wrap at 360–412dp.
- **Busiest-hours heatmap** (`BusiestHoursHeatmap`) — day × 2-hour-bucket
  heatmap (7am–11pm) replacing the crowded 24-slot chart.
- **Logout relocation** — admin logout removed from the top bar and added to
  Settings as a destructive `LogoutListTile` (same confirm-dialog flow);
  `logout()` now writes an audit event.

### Added (admin UX & responsive modals)

- **Responsive modal helper** (`shared/ui/ui_modal.dart`) —
  `showUiAdaptiveModal` renders a centred dialog (max 560dp) on desktop and a
  bottom sheet with a `FractionallySizedBox` on phones/tablets. Staff add/edit
  and Product add/edit forms now adapt to the device instead of always using
  `showModalBottomSheet`.
- **Session-aware change password** (`change_password_dialog.dart`) — verifies
  the current PIN against the persisted hash (admin →
  `admin_pin_hash` in SharedPreferences; waiter → the `staff` SQLite row) and
  writes the new hash; records a `password_changed` audit event.
- **Admin Settings account card** — shows the signed-in identity, plus Change
  password, Log out and "Reset business data" actions; profile header renders
  avatar initials + role/on-shift state.
- **Admin sidebar footer** (`shared/widgets/nav_user_footer.dart`) — the
  desktop sidebar now pins an account row (avatar, username, role badge,
  logout) via a new `drawerFooter` slot on `AppShell`.
- `UiCard` gained a `content` slot for dense bodies (filter rows, staff cards)
  and a `titleColor` override.
- **Waiter top bar shows the database user** — `currentUserProvider` is now
  bound to the live auth session and joined against the `staff` table (admins
  use the stored admin username); the profile chip renders the signed-in
  waiter's display name + role in the phone/tablet nav shell too (role badge
  drops out on narrow screens to avoid overflow) and the settings hero reuses
  the same source of truth.

### Changed

- **Admin sidebar** remade as a clean brand header + pill-style nav list (the
  active tab gets a secondaryContainer tint) instead of the M3
  `NavigationDrawer`.
- **Admin dashboard layout** — KPI grid, then revenue beside a new rail
  (shift-status + quick-actions), then a secondary row pairing top sellers with
  low-stock alerts; reflows per width.
- **Quick actions + shift status** redesigned onto `DashboardCard`s with tappable
  icon tiles and an on-shift progress bar respectively.
- Sales Log filters now render on a single line of equal, ellipsising controls
  from ~770dp up, 2+1 on tablets and stacked on phones.
- `_StaffCard` and the Sales Log filters reuse `UiCard`.

### Fixed

- **Dashboard chart overflowed on phones/tablets** (`admin_dashboard_page.dart`)
  — the revenue overview and the shift-status/quick-actions rail were always
  placed side by side in a `Row` even when there wasn't enough width, each
  taking full width and overflowing horizontally by the rail's width. They now
  stack vertically below the 1100dp breakpoint, matching the documented
  mobile/tablet layout.

### Fixed

- **Dynamic-color flash at launch** (`main.dart`) — `DynamicColorBuilder`
  now sits behind a `_PaletteGate` that holds a flat, theme-independent
  background until the platform accent (Material You / wallpaper on Android,
  GTK accent on desktop) resolves, so the UI never paints with the coffee
  fallback and snaps to the native scheme a frame later. A short grace period
  falls back to the coffee seed on platforms that never answer.
- **Date-range picker landed on the current month** even when the applied
  window was months/years old; it now anchors on the currently filtered window
  (`currentDate: _range?.start`).
- Product/Waiter filter dropdowns ellipsise (`isExpanded`) so the single-line
  filter row can't overflow at ~770–900dp widths.

### Changed

- **PIN redesigned from 6 to 4 digits** (`kAdminPinLength` / `kStaffPinLength`)
  — the login keypad, onboarding PIN setup, staff add/edit form and the
  change-password dialog all share the single constant; demo credentials are
  now `admin`/`1234` and `waiter*`/`1111`–`3333` in debug builds.
- `LoginForm` drops focus before submitting (avoids a blinking-cursor ticker
  lingering on the replaced login route).
- New tests: `order_number_test.dart` (sequential per-day, daily reset,
  concurrent assignment), `audit_repository_test.dart`, `sales_query_repository_test.dart`
  (filters + heatmap buckets), `product_archive_test.dart` (soft delete /
  un-archive / hard delete) and `database_migration_test.dart` (v1 → v2 data
  preservation). `login_flow_test.dart` now drains real-async SQLite replies
  between frames so the routed dashboards settle deterministically.

### Fixed

- **Sales Log table never appeared** (`sales_log_page.dart`) — `_loading`
  started as `true`, so the very first `_load()` hit its own
  `if (_loading) return;` guard in `initState` and the page stayed on the
  forever-spinning loader. Initialised to `false` so the initial fetch (and
  every filter change) actually runs.
- **Sales Log filters**: the Product/`Waiter` dropdowns overflowed by 14px at
  their fixed 260dp width (prefix icon left only ~180dp for "All products" +
  the arrow). Filters are now `LayoutBuilder`-driven: a single aligned row of
  evenly sized controls when there's room (desktop), 2+1 on tablets and a
  full-width stack on phones — no more yellow/black stripes at any width.
- Sales Log + add-product layouts covered by widget tests
  (`sales_log_page_test.dart`: table renders and filter row reflows without
  overflow at 1200 / 800 / 412 / 360dp; the add/edit product sheet renders
  without horizontal overflow on phone widths).

### Added (persistence & admin dashboard)

- **SQLite persistence layer** (`core/db/app_database.dart`, models under
  `core/models/`, repositories under `core/repositories/`) — the POS now stores
  real data instead of working from in-memory StateProviders:
  - `products`, `orders`, `order_items` and `staff` tables with a 1.x in-app
    database opened via `sqflite` (`sqflite_common_ffi` in tests), plus
    `deleteAllData()` for the settings reset.
  - `Product`, `OrderRecord`, `OrderLineItem` and `StaffMember` models with
    `toRow`/`fromRow` mappers and `Product.isLowStock`.
  - `ProductRepository` (catalog, availability, stock decrement + `restock`,
    low-stock query) and `StaffRepository` (roster, active members,
    username lookup, upsert / delete / deactivate) with mutation
    counters (`productMutationProvider`, `staffMutationProvider`) so watchers
    recompute after every write.
  - `OrderJournalRepository` — aggregate queries backing every dashboard number:
    `statsBetween` (revenue/orders/items/avg), `revenuePerDay`, `topProducts`,
    `revenueByHour`, `salesByWaiter`, `revenueByCategory`, plus `addOrder` +
    `nextOrderId` and the `journalMutationProvider` counter.
  - Waiter checkout now persists each order to the journal and decrements
    product stock (ticket numbers stay in sync across restarts).
  - Admin "Reset onboarding" now wipes the SQLite database too.
- **Real admin Dashboard** (`AdminDashboardPage` + widgets under
  `features/admin/widgets/`) replacing the placeholder:
  - Period selector (Today / Last 7 days / Last 30 days) feeding a shared
    `dashboardPeriodProvider`.
  - KPI cards (revenue, orders, items, avg order value) with delta chips vs. the
    previous equal-length window.
  - Dependency-free revenue trend chart via `CustomPainter`
    (`RevenueTrendChart`), zero-filled per period (`hourly` today, daily
    otherwise).
  - Top products list (ranked best sellers with revenue bars), low-stock
    alerts with one-tap `+ Restock`, shift-status card and dashboard header
    greeting + date.
- **Menu & Products admin tab** — 5th `AppShell` destination; now the editable
  catalog (replace placeholder).
- `AppShell.indexController` — optional `ValueNotifier<int>` so dashboard quick
  actions can jump straight to Staff / Reports / Menu from the Dashboard.

### Added (management tabs — Staff, Reports, Menu, Settings)

- **Staff tab** (`StaffManagementPage`): reactive roster with live
  active/total count; phone cards vs. `DataTable` on wide screens; add/edit
  via bottom sheet (name, unique username, 6-digit PIN hashed with `hashPin`,
  blank PIN on edit keeps the stored hash); deactivate / reactivate / delete
  with confirm dialogs (deactivation keeps sales history attributed). Writes go
  through `staffMutationProvider` (`setActive`, `delete`).
- **Reports tab** (`ReportsPage`): revenue-over-time line chart
  (`RevenueLineChart`, CustomPainter line + gradient area), category mix
  (horizontal bars with share %), busiest hours (24 fixed hour slots of order
  counts, reusing `RevenueTrendChart` via a new non-currency `valueFormatter`)
  and team performance (per-waiter revenue/orders). All driven by
  `analytics_provider.dart` (`categoryMixProvider`, `busiestHoursProvider`,
  `waiterPerformanceProvider`) for the shared dashboard period.
- **Menu & Products tab** (edit): responsive product card grid (photo,
  category, price, stock line) with add/edit sheet (name, price, category,
  image picker over the bundled `assets/stack_imgs/`, stock + low-stock
  threshold, availability), in-service `AvailabilityToggle`, and delete with
  confirm. Every write bumps `productMutationProvider` (`upsert`, `delete`,
  `setAvailable`) so the waiter menu and dashboard alerts update live.
- **Settings polish**: `theme_segmented_control.dart` and `language_dropdown.dart`
  extracted as shared widgets (both dashboards now use them); `AdminSettingsPage`
  gained a General card (language + theme) and dropped its nested Scaffold to
  match the other tabs; reset still wipes the DB and returns to onboarding.

### Changed

- Period window helpers live in `features/admin/providers/dashboard_period.dart`
  (`DashboardPeriod`, `DateRange`, `periodRange`/`previousRange`, `deltaPercent`)
  — the single source of truth for "what window am I looking at".
- Tests cover the new stack: `dummy_data_seeder_test.dart` (debug seeder
  writes staff + sample sales), an expanded `login_flow_test.dart` (admin and
  waiter login through the real database), `order_journal_test.dart` (window
  stats, ticket continuity, top products, hourly buckets, team + category
  aggregates, snapshot survival) and `staff_crud_test.dart` (upsert, lookup,
  deactivate, delete, username uniqueness).

### Added (login & auth)

- **Login page** (`LoginPage`) — entry point after onboarding, shared by the
  admin and waiter roles:
  - One screen with an Admin/Waiter `SegmentedButton` role switch that swaps the
    contextual field labels in place (no navigation, entered username kept).
  - Admin login validates against the real onboarding-created credential; waiter
    login validates against stored waiter accounts.
  - `PinKeypadField` reused for PIN entry with shake-on-error and an inline
    generic "Incorrect username or PIN" message on failure (clears PIN, keeps
    username).
  - Successful login routes to the matching dashboard via `pushReplacement`;
    logout returns to `LoginPage` on a fully cleared stack.
- **Auth state** — `authProvider` (`AsyncNotifier<AuthState?>`) holds the
  session (role, userId, username) with `login()`/`logout()`; the session never
  survives a restart (no "stay logged in").
- **Debug dummy accounts seeder** (`core/dev/dummy_data_seeder.dart`) — seeds
  `admin` / `123456` and `waiter1` / `111111` in debug builds only, never in
  release (`kDebugMode` guarded at the call site and inside).
- **Shared `AuthScreenLayout`** — generic responsive auth shell (compact /
  medium / expanded) extracted and reused by both onboarding and login so the
  two screens share the same visual treatment.
- **Shared `LogoutButton`** — app-bar logout action with a confirm dialog,
  wired into both the admin and waiter dashboards.
- `Role` enum in `core/models/user_role.dart`; SHA-256 PIN hashing in
  `core/security/password_hash.dart`.
- Last-selected role toggle persisted via SharedPreferences as a UX convenience.

### Changed

- Onboarding now persists the admin's username + hashed PIN alongside the
  completion flag, so login can validate against the real account.
- Admin "Reset onboarding" now also clears the stored credentials and session,
  matching its "delete the admin account" wording.
- Startup routing: onboarding not yet done → `OnboardingPage`, done → `LoginPage`.
- `PinKeypadField` gained a `resetSignal` so an external caller can clear the
  entered PIN (used on failed login) while preserving the shake animation.

### Added (onboarding)

- **Onboarding screen** — one-time admin setup flow shown on first launch.
  - Username field with inline validation (3–24 chars, alphanumeric + underscore).
  - Custom 6-digit PIN keypad with animated dot indicators and shake-on-error.
  - Confirm-PIN step replaces the PIN keypad in place (no scroll required).
  - "Finish setup" button disabled until all fields valid; inline errors under
    each field.
  - Persisted `onboarding_complete` flag via SharedPreferences; app skips
    straight to admin dashboard on subsequent launches.
- **Responsive onboarding layout** — three breakpoints:
  - Compact (< 600dp): Brewline logo + wordmark header, full-width form.
  - Medium (600–905dp): branded header above a centered card (480dp max).
  - Expanded (≥ 905dp): two-pane — brand sidebar (360dp) + centered form.
- **Admin settings page** (`AdminSettingsPage`) with a "Reset onboarding" button
  that clears the persisted flag and navigates back to the onboarding screen.
  - Confirmation dialog before reset.
  - `pushAndRemoveUntil` so onboarding is not reachable via back button.
- **Shared widgets**:
  - `AppTextField` — canonical M3-styled text field (16dp rounded outlined
    border, label + inline error slot, dynamic color). Reusable app-wide.
  - `PinKeypadField` — self-contained numeric keypad with dot row, animated
    error shake, and press-state feedback. Reusable for future login screen.
- `kAdminPinLength` constant in `core/constants/app_sizes.dart`.

### Changed

- **Folder structure refactor** — flattened feature directories to remove the
  `data/` and `presentation/` nesting that was confusing and overly deep:
  ```
  Before                              After
  features/{name}/data/providers/     features/{name}/providers/
  features/{name}/presentation/pages/ features/{name}/pages/
  features/{name}/presentation/widgets/ features/{name}/widgets/
  ```
  All imports updated across the entire codebase (13 source files + 1 test).
- Admin home page now includes a **Settings** tab (4th destination in
  `AppShell`).
- `OnboardingPage` now watches `onboardingCompleteProvider` and navigates to
  `AdminHomePage` on success via `pushReplacement`.

### Fixed

- Onboarding PIN confirmation no longer requires scrolling — single keypad
  slot cross-fades between "Set your PIN" and "Confirm your PIN" phases.
- Mobile/tablet onboarding layout uses `BrandTitle` wordmark instead of a bare
  icon, with proper spacing and a divider separating header from form.
- PinKeypadField buttons tightened (68×48, 6px gaps) for better mobile fit.

[Unreleased]: https://github.com/example/brewline/compare/1.2.0...HEAD
[1.2.0]: https://github.com/example/brewline/compare/1.1.1...1.2.0
[1.1.1]: https://github.com/example/brewline/compare/1.0.0...1.1.1

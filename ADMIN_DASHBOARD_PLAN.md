# Admin Dashboard — Implementation Plan (Brewline / Café POS)

**Status:** Approved — decisions taken on 2026-08-29.
**Progress:** Phases 0–5 **done** (dashboard, staff, reports, menu, settings) — `flutter analyze` clean, 26 tests green.
**Decisions:**
- **Data foundation:** persistence layer first, then dashboards (numbers must be real).
- **Charting:** hand-rolled `CustomPainter` charts — no new visual dependency.
- **Scope:** add a Menu/Products management tab; Staff and Reports are built now too.

---

## Goal

Replace the placeholder Dashboard/Staff/Reports tabs in `AdminHomePage` with
working management screens, backed by a **persisted** order journal, product
store and staff table. Every number on screen must come from real data the
waiter POS writes.

Current state (what is being replaced/rewired):

- `AppShell` (`shared/widgets/app_shell.dart`) renders Dashboard, Staff, Reports
  as a centered label placeholder; only Settings has real content.
- Orders are in-memory only — `OrderController.charge()`
  (`features/waiter/providers/order_provider.dart`) logs to the terminal and
  drops the cart. **KPI/report data simply does not exist yet.**
- Products are a hard-coded list (`features/waiter/providers/product_provider.dart`).
- Waiter accounts live in a JSON map in SharedPreferences (`waiter_accounts`).

---

## Phase 0 — Persistence foundation

**New dependencies:** `sqflite`, `sqflite_common_ffi` (SQLite on desktop/tests),
`path`. Consistent with the stack already declared in `improve.md`.
SharedPreferences stays for small keys (auth, theme, onboarding, locale).

**New files:**

```
lib/core/db/app_database.dart                    // Database + schema + migration helper
lib/core/repositories/
  product_repository.dart                        // product CRUD + stock queries
  order_journal_repository.dart                  // insert order+items, SQL GROUP BY aggregates
  staff_repository.dart                          // waiter accounts (replaces JSON map)
lib/core/models/
  product.dart                                   // migrated up from features/waiter/...
  order_record.dart                              // completed order
  order_line_item.dart                           // product snapshot line
  staff_member.dart                              // waiter account
```

**Tables:**

| Table | Columns |
|---|---|
| `products` | id, name, price, image_path, category, available, low_stock_threshold |
| `orders` | id (ticket # PK), created_at, waiter_username, total |
| `order_items` | order_id, product_id, name_snapshot, qty, unit_price |
| `staff` | id, username, pin_hash, name, active, created_at |

**Rewiring the producer side (waiter POS):**

- `OrderController.charge()` → insert order + `order_items` into the journal,
  stamp with the signed-in waiter from `authProvider`, then reset cart + advance
  ticket number. Replaces today's terminal-log TODO.
- `productsProvider` → DB-backed stream so the waiter menu live-updates when the
  admin edits a product. `Product` model moves to `core/models/`.
- `authProvider` waiter lookup reads the `staff` table instead of
  `kWaiterAccountsKey`. Dummy seeder seeds the same rows. Admin "Reset
  onboarding" also clears the DB tables.

---

## Phase 1 — Admin Dashboard tab (overview) ✅ done

Answers: *"How is business going right now?"* One screen, no digging.

Built (as planned, with two deviations: low-stock lives in
`core/repositories/product_repository.dart` as `lowStockProductsProvider`, and
the quick actions are Add staff / View reports / Add product):

```
lib/features/admin/
  pages/admin_dashboard_page.dart
  providers/dashboard_period.dart                // DashboardPeriod, DateRange, periodRange, deltaPercent
  providers/dashboard_provider.dart              // KPIs + prev-window deltas
  providers/sales_trend_provider.dart            // hourly (today) / daily (7d, 30d) series
  providers/top_products_provider.dart
  widgets/
    dashboard_header.dart                        // greeting + date + PeriodSelector
    period_selector.dart
    kpi_card.dart                                // icon, value, delta chip
    revenue_trend_chart.dart                     // CustomPainter bars (+ stable fill)
    top_products_list.dart
    low_stock_alerts.dart                        // + Restock via productMutationProvider
    shift_status_card.dart
    quick_actions_row.dart                       // jumps tabs via AppShell.indexController
```

Dashboard wiring: `AdminHomePage` now has 5 destinations (Dashboard, Staff,
Reports, Menu, Settings) and passes a `ValueNotifier<int>` (`AppShell.
indexController`) so quick actions can switch tabs. Staff and Reports remain
placeholders until Phases 2–3.

CPIs surfaced: revenue today, orders today, avg order value, items sold — each
with a delta vs. an earlier window.

---

## Phase 2 — Staff tab ✅ done

- `pages/staff_management_page.dart` — roster header ("X of Y active") + Add.
- `widgets/staff_table.dart` — active-first reactive roster; cards on phones,
  `DataTable` on wide screens; edit / activate / deactivate / delete via menu,
  with confirm dialogs (history stays attributed after deactivate).
- `widgets/staff_form_sheet.dart` — add/edit: name, username (unique), PIN
  4-digit (create: required, edit: blank keeps stored hash), hashed via
  `hashPin`.
- Writes go through `staffMutationProvider` (now exposing `setActive`/`delete`).

## Phase 3 — Reports tab ✅ done

- `core/repositories/order_journal_repository.dart` + `revenueByCategory`
  (LEFT JOIN products, "Other" fallback for deleted products).
- `providers/analytics_provider.dart` — `categoryMixProvider`,
  `busiestHoursProvider` (24 fixed hour slots), `waiterPerformanceProvider`.
- `pages/reports_page.dart` + widgets: `revenue_line_chart.dart`
  (CustomPainter line + area), `category_mix_bars.dart`,
  `busiest_hours_bars.dart` (reuses `RevenueTrendChart` — gained a
  `valueFormatter` for non-currency peaks), `team_performance.dart`.
- Reuses `PeriodSelector` + `dashboardPeriodProvider`.

## Phase 4 — Menu/Products tab ✅ done

- `pages/menu_products_page.dart` — editable catalog (name kept from Phase 1;
  plan's `menu_management_page.dart` name was folded here).
- `widgets/product_table.dart` — responsive grid of product cards (photo,
  category, price, stock line, edit/delete menu).
- `widgets/product_form_sheet.dart` — name/price/category, image picker from
  the bundled `assets/stack_imgs/`, stock + low-stock threshold, availability.
- `widgets/availability_toggle.dart` — in-service switch.
- Writes via `productMutationProvider` (now exposing `upsert`/`delete`/
  `setAvailable`/`restock`) so waiter menu + dashboard alerts update live.
- Deviation: no `product_admin_provider.dart` — the form sheet is
  self-contained and writes through the shared repository provider (same
  pattern as Staff).

## Phase 5 — Settings & polish ✅ done

- Shared `shared/widgets/settings/theme_segmented_control.dart` +
  `language_dropdown.dart` extracted from the waiter settings; both dashboards
  use them now.
- `AdminSettingsPage` rebuilt: language + theme card (destructive reset kept,
  now also clears business data). Dropped its nested Scaffold/AppBar to match
  the other tabs inside `AppShell`.

---

## Verification

- `flutter analyze` clean; dartdoc on all new public classes (repo convention).
- Unit tests for journal aggregates + repository CRUD + "charge persists order"
  (mirror `test/dummy_data_seeder_test.dart` style); widget tests for `KpiCard`,
  charts, staff/product form sheets.
- Manual: charge a few waiter orders → numbers appear on Dashboard and Reports;
  add a product → appears on the waiter menu.

---

## Notes / risks

- SQLite introduces the first real schema + migration step and desktop FFI init
  in `main()`. This matches the declared stack (`sqflite_common_ffi`).
- Aggregates stay in SQL (`GROUP BY`) so reports scale to months of order
  history instead of loading everything into memory.
- SharedPreferences keeps auth/theme/onboarding strings; DB owns business data.
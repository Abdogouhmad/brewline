# brewline

**Local-first café POS & CRM** — a cross-platform Flutter application for independent coffee-shop operations. brewline runs entirely on the café's own hardware (Android tablets, Windows/Linux PC) with a local SQLite database, so it keeps working without internet and never sends business data to a third party.

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

---

## Concept

A single-tenant, on-premises point-of-sale for cafés:

- **Waiter POS** — a mobile-first ordering surface for taking orders, charging, printing kitchen/client receipts, and cashing out per shift.
- **Admin & CRM** — dashboards, sales analytics, staff management, menu/product catalog, inventory (ingredient-level stock), refunds, and an audit trail of every sensitive action.
- **Desktop parity** — the same codebase runs the front counter on a Windows PC or Linux terminal, with a responsive UI (phone → tablet → desktop) and an in-app OTA updater for both Android and desktop installs.

The app is designed to be self-hosted by a café owner: no accounts, no cloud sync, no subscriptions — the device is the server.

---

## Features

### Point of Sale
- PIN-only login with automatic role routing (Admin vs. Waiter), SHA-256-hashed PINs and brute-force throttling
- Daily sequential order numbers, persisted per-day counters
- Charge flow with automatic kitchen (55 mm) + client (88 mm) ESC/POS receipt printing
- Shift cash-out ledger with counted-cash variance and audit logging
- Refund system: partial/full refunds with reasons, `void` and `post_print_edit` audit signals

### Admin & Analytics
- KPI dashboard (Today / 7 / 30 days) with delta vs. previous window, revenue trend chart, busiest-hours heatmap, top products, low-stock alerts
- Sales log with date/product/waiter filters
- Cashout logs with date-range and waiter filters
- Reports tab: revenue-over-time, category mix, team performance

### Catalog, Staff & Inventory
- Menu & Products management with gallery images, availability toggles, stock + reorder thresholds
- Staff roster management (add/edit/deactivate) with unique-pin enforcement
- Ingredient-level stock: recipes, live quantities in atomic smallest units, append-only `stock_movements` ledger

### Trust & Operations
- **OTA updates** via GitHub Releases API: per-platform artifacts (APK / Windows zip / Linux tar.gz), SHA-256 verified downloads, versioned install directories (never overwrites the running binary), mandatory-update gate
- Receipt printing over raw TCP (port 9100) or USB (`flutter_pos_printer_platform_image_3`) with typed offline/timeout errors
- Dynamic color theming (Material You / platform accent) with a coffee-brand fallback seed, light + dark
- Localization: English and French (Settings → **English / Français / System default**), device-level preference with `intl`-driven number/date formatting; receipts print in their own fixed language (default French)

> **Adding a new string:** user-facing text lives in `lib/l10n/app_en.arb` (the template) and is translated outward to `app_fr.arb` — never the reverse. Run `flutter gen-l10n` (see `l10n.yaml`); keys in the template but missing from a translation surface as warnings. In code, read through `AppLocalizations.of(context)`; money/date formatting goes through `core/utils/price_format.dart` / `date_format.dart`.

---

## Tech Stack

| Concern | Choice |
| --- | --- |
| Framework | Flutter (Dart `^3.13`) |
| State management | `flutter_riverpod` (Riverpod v3) |
| Persistence | SQLite — `sqflite` (Android/iOS) + `sqflite_common_ffi` (desktop), native library bundled by `sqlite3_flutter_libs` |
| Async HTTP | `dio` |
| Receipts | `esc_pos_utils_plus`, `flutter_pos_printer_platform_image_3` |
| Packaging | `archive`, `pub_semver`, `package_info_plus` |
| Linting | `flutter_lints` |

**Supported targets:** Android · Windows · Linux · iOS · macOS · Web

> **Desktop SQLite note:** `sqflite_common_ffi` loads SQLite over `dart:ffi`, so desktop builds ship the native `sqlite3.dll` / `libsqlite3.so` next to the executable via `sqlite3_flutter_libs`. See [CHANGELOG](./CHANGELOG.md) `1.6.1` for the launch-crash regression this fixed.

---

## Architecture

The codebase follows a feature-first, layered structure with Riverpod providers as the state layer. The domain is database-backed with repository interfaces; the presentation layer never touches SQL directly.

```
lib/
├── main.dart                       # Startup, guarded error screen, update gate, palette gate
├── core/                           # Framework-agnostic shared code
│   ├── auth/                       # PIN lookup, hashing, login state
│   ├── db/                         # SQLite schema, migrations (v1→v5), open/seed/reset
│   ├── repositories/               # products, orders, staff, cashouts, refunds, stock, audits
│   ├── printing/                   # printer transport, ESC/POS receipt templates
│   ├── updates/                    # GitHub Releases API, installers, update state machine
│   ├── localization/               # System / English / Français + receipt language
│   ├── theme/ · responsive/        # dynamic theme, breakpoints
│   └── services/ · constants/ · models/ · security/ · navigation/
├── features/
│   ├── admin/                      # dashboards, sales log, cashout logs, inventory, staff, reports
│   ├── waiter/                     # menu, orders, settings, cash-out
│   ├── auth/                       # PIN login screen + keypad
│   └── onboarding/                 # first-run admin setup
└── shared/ · widgets/              # cross-feature UI primitives (UiCard, adaptive modals, …)
```

### Data layer

- **Database:** single `brewline.db` opened at v5, migrations replayed from `kMigrations` on upgrade; money stored as integer cents, quantities as integers in each ingredient's smallest unit.
- **Audit trail:** `audit_events` records login, logout, cashout, report print, password change, void and post-print edits — the fraud-detection signals.
- **Repositories** expose mutation counters (e.g. `productMutationProvider`) so Riverpod watchers recompute after every write without manual invalidation.

### Resilience

- Startup is wrapped in a guarded error screen (message + "Copy error") instead of a silently vanishing process.
- Desktop OTA installs extract to a fresh versioned directory and relaunch with a delay so file locks are released cleanly.
- Downloads fail closed: any checksum mismatch is deleted and surfaced, never applied.

---

## Getting Started

**Prerequisites:** Flutter SDK (stable) on PATH; for Windows builds, Visual Studio with C++ toolchain; for Linux, GTK 3 dev headers.

```sh
# Install dependencies
flutter pub get

# Run on a device / desktop target
flutter run -d linux        # or -d windows, -d android

# Quality gates
flutter analyze
flutter test
```

A `justfile` ships common recipes (`just deps`, `just analyze`, `just test`, `just check`, `just build-linux`, `just build-windows`, `just build-android`, `just clean`, `just reset`). `just` is optional — plain `flutter` commands work the same.

### Release builds

```sh
# Everything the current OS can produce
./build.sh

# Individual targets
./build.sh --only linux      # build/linux/x64/release/bundle/
./build.sh --only windows    # build/windows/x64/runner/Release/   (Windows host)
./build.sh --only android    # universal APK + per-ABI APKs + AAB
```

CI ([`.github/workflows/release.yml`](.github/workflows/release.yml)) builds Linux + Android on `ubuntu-latest` and Windows on `windows-latest`, archives the **entire** build output directories into `brewline-linux-x64.tar.gz` / `brewline-windows-x64.zip`, and publishes a GitHub release tagged from `pubspec.yaml`'s `version:` field. Release notes are extracted from the matching `## [<version>]` section in [CHANGELOG.md](./CHANGELOG.md).

---

## Versioning

Follows [Semantic Versioning](https://semver.org/). The version lives in `pubspec.yaml` (`<major>.<minor>.<patch>+<build>`); the git tag and release notes derive from it automatically. For Windows builds the `Runner.rc` version block should be kept in sync.

See [CHANGELOG.md](./CHANGELOG.md) for the full release history.

---

## License

[Apache License 2.0](LICENSE)

brewline is built with Flutter and the Flutter ecosystem — see [pubspec.yaml](pubspec.yaml) for the full dependency list.
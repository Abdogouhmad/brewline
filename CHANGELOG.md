# Changelog

All notable changes to Brewline, in plain language for everyday users.

## [1.14.0] - 2026-09-18

### Improved (design)

- **More consistent page headers** — Inventory and Menu now share the same
  title/subtitle header as the rest of the admin pages, so the layout no
  longer jumps between tabs on phones.
- **Cards look the same everywhere** — KPI, dashboard and ingredient cards now
  draw their frame from one shared style, so corners, borders and spacing are
  uniform.
- **Filters keep their place** — the current order number on the waiter board
  no longer re-fetches on every rebuilt list, so the screen stays smooth while
  orders come and go.
- **Clearer charge confirmation** — after charging an order, a small success
  message confirms the total, alongside the printed receipt.
- **Cleaner bottom navigation** — on phones the tab bar is now icon-only (the
  screen title names the active tab), and several loading/placeholder states
  are properly themed.

### Fixed

- **No more flicker in Settings** — the profile card keeps a stable size while
  your details load instead of shifting the page.
- **Cash-out dialog cleanup** — the cash-count field is now disposed correctly,
  preventing a small memory leak each time the dialog is closed.
- **Quieter archive action** — ingredient archiving is handled by a dedicated
  provider instead of rebuilding the whole page.

### Under the hood

- Long inventory lists are now built lazily as you scroll, so a large ingredient
  catalog stays responsive.
- Removed dead order code (`orderTitleProvider`, the unused order-number
  controller) and simplified the PIN keypad, chart rail and dashboard layout
  breakpoints.

## [1.13.0] - 2026-09-15

### Improved (design)

- **Full Material 3 component theming** — every button, card, dialog, sheet,
  input field, navigation bar, chip, switch, snackbar and menu now has a
  consistent, scheme-aware default style baked into the theme, so widgets look
  correct without per-instance overrides.
- **M3 expressive ripple** — all tappable surfaces now use the softer
  `InkSparkle` gradient ripple instead of the flat Material ink splash.
- **Smarter cards on hover** — tappable cards lift with a subtle branded shadow
  and tint on hover (desktop), and compress slightly when pressed, making
  interactive surfaces feel alive.
- **Button press micro-interaction** — buttons sink 2% on press with a
  fast 100 ms ease-out, giving tactile feedback without a separate tap effect.
- **Consistent page transitions** — FadeForwards on Android, Windows and Linux;
  smooth crossfade between screens replaces the abrupt default.
- **Unified motion tokens** — new `AppMotion` constants (100 ms – 700 ms
  durations, standard/emphasised/exit curves) replace scattered hardcoded
  durations across shared widgets.

### Improved (code quality)

- **Zero hardcoded colours** — `Colors.green.shade600` on the waiter profile
  and `Colors.black` shadows on staff cards now derive from the active
  `ColorScheme`, so they follow dynamic colour and dark mode correctly.
- **No raw `MediaQuery` width checks** — stock movements and dashboard KPI
  cards now use the shared `Breakpoints` API, keeping responsive layout logic
  in one place.
- Revenue chart paint helpers enforce a required `color` parameter instead of
  defaulting to `Colors.black`, preventing invisible text in dark mode.

## [1.12.0] - 2026-09-12

### Improved (design)

- **One consistent look everywhere** — every screen (login, dashboard, menu,
  stock, sales and settings) now shares the same colour scheme, spacing and
  rounded corners pulled from your device theme, so nothing looks out of
  place and the interface reads as a single design.
- **Standard loading, empty and error panels** — lists throughout the app
  (sales log, cashout log, stock, inventory, reports, low-stock alerts) now
  show the same clear progress, "nothing here yet" and error messages.
- **Consistent status badges** — stock low/out, refunds, shift status,
  availability and update status all use the same badge style and live
  indicator dots.
- **Neater tables on desktop** — reports and staff tables now share a tidy
  header, divider and row rhythm that match the rest of the app.

### Improved (desktop & accessibility)

- **Type your PIN from the keyboard** — on Windows and Linux you can now type
  the PIN digits, use Backspace to erase and Enter to submit; the on-screen
  keys also show a pointer cursor and press highlight.
- Every icon button now explains itself with a tooltip, and icons use one
  consistent style.

## [1.11.0] - 2026-09-11

### Added

- **Backup & restore** — protect your business data. A single admin-only "Data"
  section in Settings can now pack your whole store (products, sales history,
  recipes, stock, staff and reports) into one `.brewline` file you can move
  anywhere, and restore it to this or another device. Restoring replaces the
  device's data, and a safety snapshot of the current data is saved
  automatically first so nothing is ever lost.
- **Update notifications** — the app now shows a notification (Android tray /
  Windows & Linux toast) the moment it finds a new version, so updates surface
  even when you're not looking at Settings.

### Fixed

- **Restoring a backup never gets stuck** — on some devices the restore could
  sit on "Restoring…" forever. It now completes and signs you out to the login
  screen ready for the restored PIN, on Android, Windows and Linux. If anything
  does go wrong mid-restore, your previous data is put back automatically
  instead of the app getting stuck.

## [1.10.0] - 2026-09-10

### Added

- **The app now speaks English or French** — switch the whole interface
  between **English** and **Français** anytime in Settings, or follow your
  device's language. No restart needed.
- **Choose the receipt language** — receipts print in their own fixed language
  (French by default), independent of the app language.
- **Windows installer** — every release now also ships a classic `setup.exe`
  installer alongside the portable version.

### Fixed

- The "Add staff" quick action now opens the Staff page (it used to jump to
  Inventory).

### Improved

- Waiter checkout is less noisy — the removed "Charged $X" message means the
  printed receipt is the single confirmation of payment.

## [1.9.1] - 2026-09-09

### Fixed

- Dashboard cards no longer clip their status badge on narrow screens.
- Revenue chart labels no longer spill past the edges of the chart.

## [1.9.0] - 2026-09-09

### Improved (design)

- **Settings pages redesigned** — sections are now neatly grouped with clear
  headers (Preferences, Security, Hardware, Receipts…), so related options are
  easy to spot.
- Settings rows feel more interactive, with visible press feedback.
- Polished profile header, footer brand mark, and a smarter theme switcher.

## [1.8.0] - 2026-09-09

### Improved (design)

- **Menu & Products** management restyled for a cleaner, more consistent look.
- **Inventory** rebuilt as a tidy ingredient list with an expandable
  add-product button.

## [1.7.0] - 2026-09-08

### Security

- **Stronger PIN storage** — PINs are now stored with per-user salt; existing
  accounts are upgraded automatically the next time they sign in.
- **Admin credentials protected** — sign-in details now live in the device's
  secure storage (Android Keystore / iOS Keychain), not plain files.

### Fixed

- The login screen no longer freezes during the 30-second lockout after too
  many wrong PINs — the countdown keeps running and you can try again when it
  ends.
- More reliable desktop builds.

### Under the hood

- All prices are now handled as integer cents, removing rounding errors from
  totals and reports.

## [1.6.1] - 2026-09-06

### Fixed

- **First launch no longer fails on Windows/Linux** — the desktop app now
  bundles the SQLite library it needs, fixing a crash on clean installs.
- A startup problem now shows a clear error screen with a "Copy error" button,
  instead of the app silently closing.

## [1.6.0] - 2026-09-06

### Improved

- **More reliable in-app updates** — update checks now read directly from the
  latest GitHub release, so what you see in the app always matches what was
  published.
- On Android, the correct build for your device is selected automatically.
- Android release updates now use a consistent signature, so updates install
  over previous versions without forcing an uninstall.

## [1.4.0] - 2026-09-03

### Changed

- **PIN-only login** — no more username or role selector. Type your 4-digit
  PIN and you're taken straight to your dashboard.

### Added

- **No duplicate PINs** — every staff and admin PIN must be unique, enforced
  everywhere a PIN is created or changed.
- **Bonus protection** — after 5 wrong PINs, the keypad locks for 30 seconds
  with a visible countdown.
- The login keypad now scales up comfortably on tablets and desktops.

## [1.3.1] - 2026-09-02

### Fixed

- **Windows updates no longer need administrator rights** — installing an
  update no longer requires Developer Mode or admin privileges.
- If the app fails to start, you now see a helpful error screen with a
  "Copy error" button to share the details.
- Android updates install cleanly over previous versions (stable signing), so
  you no longer need to uninstall first.

## [1.3.0] - 2026-09-01

### Added

- **In-app updates for Android, Windows and Linux** — the app checks for new
  versions on launch (toggleable) and downloads them straight from Settings.
- **Mandatory updates** — when a required update is available, the app asks you
  to install it before continuing.
- **Secure downloads** — every update is verified before installation.

## [1.2.1] - 2026-08-30

### Fixed

- Network printing now works in Android release builds, not just during
  development.

## [1.2.0] - 2026-08-30

### Added

- **Printer support** — print kitchen tickets, 88 mm client receipts, and
  shift-end reports over the network or USB, set up from Settings → Printer.
- **Cash out & print** — waiters can close their shift from Settings: confirm
  the counted cash, a report prints, and the close is recorded.
- **Print report** — an on-demand interim report, clearly marked as a preview.
- **Cashout log for admins** — filter past cash-outs by date and waiter.
- Receipts print automatically after each sale (toggleable).

## [1.1.1] - 2026-08-30

### Added

- **Real admin dashboard** — revenue/orders KPIs, trends, top sellers and
  low-stock alerts with one-tap restocking.
- **Sales log** — filter past sales by date, product or waiter.
- **Product photos** — add images to menu items (chosen from your device).
- **Works on any screen** — the app now adapts between phone, tablet and
  desktop layouts.
- **Staff management** — add, edit, pause or delete waiter accounts.
- **Reports** — revenue trends, category mix, busy hours and team performance.
- **Menu & Products management** — add or edit items, manage stock and
  availability.
- **Login & onboarding** — first-run setup for the admin account, followed by
  a secure PIN login.

[Unreleased]: https://github.com/Abdogouhmad/brewline/compare/1.14.0...HEAD
[1.14.0]: https://github.com/Abdogouhmad/brewline/compare/1.13.0...1.14.0
[1.13.0]: https://github.com/Abdogouhmad/brewline/compare/1.12.0...1.13.0
[1.12.0]: https://github.com/Abdogouhmad/brewline/compare/1.11.0...1.12.0
[1.11.0]: https://github.com/Abdogouhmad/brewline/compare/1.10.0...1.11.0
[1.10.0]: https://github.com/Abdogouhmad/brewline/compare/1.9.1...1.10.0
[1.9.1]: https://github.com/Abdogouhmad/brewline/compare/1.9.0...1.9.1
[1.9.0]: https://github.com/Abdogouhmad/brewline/compare/1.8.0...1.9.0
[1.8.0]: https://github.com/Abdogouhmad/brewline/compare/1.7.0...1.8.0
[1.7.0]: https://github.com/Abdogouhmad/brewline/compare/1.6.1...1.7.0
[1.6.1]: https://github.com/Abdogouhmad/brewline/compare/1.6.0...1.6.1
[1.6.0]: https://github.com/Abdogouhmad/brewline/compare/1.5.0...1.6.0
[1.5.0]: https://github.com/Abdogouhmad/brewline/compare/1.4.1...1.5.0
[1.4.1]: https://github.com/Abdogouhmad/brewline/compare/1.4.0...1.4.1
[1.4.0]: https://github.com/Abdogouhmad/brewline/compare/1.3.1...1.4.0
[1.3.1]: https://github.com/Abdogouhmad/brewline/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/Abdogouhmad/brewline/compare/1.2.1...1.3.0
[1.2.1]: https://github.com/Abdogouhmad/brewline/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/Abdogouhmad/brewline/compare/1.1.1...1.2.0
[1.1.1]: https://github.com/Abdogouhmad/brewline/compare/1.0.0...1.1.1
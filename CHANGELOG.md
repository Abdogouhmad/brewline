# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

[Unreleased]: https://github.com/example/brewline/compare/v1.0.0...HEAD

# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

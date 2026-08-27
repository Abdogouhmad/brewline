# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New Settings screen for the waiter profile, redesigned around accent-tinted
  section cards (General / Account / Printing) with a hero header.
  - Language selector and theme preference (System / Light / Dark) segmented
    control under General.
  - Change password, cashout & print report, and log out actions under Account.
  - Kitchen / client receipt switches under Printing.
  - Responsive layout: stacked cards on phone/tablet, side-by-side General and
    Printing on wide screens.
- Shared UI primitives (`UiButton`, `UiCard`, `UiList`, `UiSnackBar`, `UiText`)
  and shared widgets (`AppShell`, `BrandTitle`, `ProfileChip`).
- Provider restructure to feature-owned folders:
  - Waiter menu catalog and order/cart state under
    `features/waiter/data/providers/`.
  - Waiter printing preferences under the same feature folder.
  - Current user moved to `features/auth/data/providers/`.

### Changed

- **Refactor:** moved feature-specific Riverpod providers out of
  `shared/providers/` into their owning feature domains (waiter, auth) for clear
  ownership and dependency direction. `shared/providers/` removed.
- **Refactor:** split the former single `product_provider.dart` into separate
  `product_provider.dart` (menu catalog) and `order_provider.dart` (cart and
  ticket number) files, sharing a small `price_format.dart` helper.
- Updated all imports across pages and widgets to reference the new provider
  locations.

### Fixed

- No user-facing behavior changes; refactor is behavior-neutral.

[Unreleased]: https://github.com/example/brewline/compare/v1.0.0...HEAD

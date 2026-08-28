# Onboarding UI — Implementation Spec (Brewline / Café POS)
 
**Audience:** opencode coding agent
**Stack:** Flutter (Android + tablet + desktop web/desktop targets), Riverpod, `flutter_secure_storage`, `sqflite_common_ffi`
**Design language:** Material 3 Expressive
**Status:** Ready for implementation — no open questions blocking start (assumptions flagged below, change constants if wrong)
 
---
 
## 1. Purpose
 
The onboarding page is a **one-time setup screen** shown only when no admin account exists yet. It collects:
 
1. Admin **username**
2. Admin **PIN** (numeric, keypad-style — not a text password)
3. **PIN confirmation**
On success, it creates the single admin credential record and marks onboarding as complete. It never touches waiter accounts — those are created later, inside the admin dashboard, by the admin themself.
 
**Out of scope for this screen:** waiter management, login screen (this is setup, not sign-in — though it shares components with login), password recovery.
 
---
 
## 2. UX Flow
 
```
[App launch] → is onboarding_complete == false?
   → yes: show OnboardingPage
   → no: skip straight to LoginPage
```
 
Single-screen flow (no multi-step wizard — keep it simple per the "simple, minimal" brief):
 
1. Brand mark (Brewline logo + wordmark)
2. Username field (standard text input)
3. "Set your PIN" — 6-digit keypad entry, masked as dots
4. "Confirm PIN" — same keypad, appears after first PIN is fully entered (or as a second field, see §5)
5. Primary button: **"Finish setup"** — disabled until all fields valid
6. Inline validation errors (no dialogs/snackbars for validation — keep errors inline under each field)
> **Assumption:** PIN length = 6 digits. Expose as a constant `kAdminPinLength = 6` so it's a one-line change if you want 4.
 
---
 
## 3. Responsive Layout
 
Use `LayoutBuilder` / breakpoints, not device checks.
 
| Breakpoint | Width | Layout |
|---|---|---|
| Compact (mobile) | < 600dp | Single column. Logo + wordmark centered at top, form below, full-width fields, generous vertical padding. |
| Medium (tablet) | 600–905dp | Same single-column structure, but form is constrained to a centered card (max width ~480dp) with more breathing room around it. |
| Expanded (desktop) | ≥ 905dp | **Two-pane layout**: fixed-width sidebar (360dp) on the left showing the Brewline logo, wordmark, and a short tagline/illustration on a solid brand-color background; form content centered in the remaining space (max width ~440dp), vertically centered. |
 
Build this as `OnboardingLayout` (see §6) that swaps between `_CompactOnboardingBody` and `_ExpandedOnboardingBody` — don't duplicate form logic, the form itself is one shared widget passed into either shell.
 
---
 
## 4. Design System (M3 Expressive, dynamic color)
 
This project uses the `dynamic_color` package — the app's `ColorScheme` is generated at runtime from the device wallpaper/system palette (Material You) via `DynamicColorBuilder`, **not** a fixed hardcoded palette. Every widget in this spec must consume color through `Theme.of(context).colorScheme`, never a literal hex value.
 
**Setup pattern (if not already wired up at the app root):**
```dart
DynamicColorBuilder(
  builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    final lightScheme = lightDynamic?.harmonized() ??
        ColorScheme.fromSeed(seedColor: kBrandSeedColor);
    final darkScheme = darkDynamic?.harmonized() ??
        ColorScheme.fromSeed(seedColor: kBrandSeedColor, brightness: Brightness.dark);
    return MaterialApp(
      theme: ThemeData(colorScheme: lightScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: darkScheme, useMaterial3: true),
      ...
    );
  },
)
```
 
- `kBrandSeedColor` = the espresso brand tone (`#3C2A21`) — this is the **fallback only**, used when the platform can't provide a dynamic palette (e.g. older Android, desktop without wallpaper extraction, or if dynamic color is unsupported on that target). On devices that do support it, the whole café brand mood is expected to shift with the user's wallpaper — that's the point of using this package, so don't fight it by re-hardcoding café tones on top.
- Map every role in this spec to the scheme, not a literal:
| Role (M3) | Use via | Usage |
|---|---|---|
| Primary | `colorScheme.primary` / `onPrimary` | Filled button, active keypad dot, focused field border |
| Secondary | `colorScheme.secondary` / `secondaryContainer` | Secondary accents, sidebar background (desktop) |
| Tertiary | `colorScheme.tertiary` | Sparse accent use only |
| Surface | `colorScheme.surface` | Page background |
| Surface Container | `colorScheme.surfaceContainer` (or `surfaceContainerHigh` for the card) | Card background (tablet/mobile) |
| Error | `colorScheme.error` / `onError` | Validation error text/border |
| Outline | `colorScheme.outline` | Unfocused field borders |
 
**M3 Expressive specifics to apply:**
- Larger corner radii on containers: 28dp on the sidebar/card, 16dp on text fields and buttons (not the flatter 4–8dp of classic M3).
- Bigger, friendlier type scale for the headline ("Set up your café") — use `displaySmall`/`headlineMedium`.
- Motion: keypad dots should do a small scale/fill transition on entry (150–200ms), not an instant snap. Button should have a subtle press state (M3 expressive uses more tactile motion than flat M3).
- Support light/dark/system `ThemeMode` — the `DynamicColorBuilder` pattern above already covers light/dark; just wire `themeMode` to the existing app setting.
- Respect the existing fixed app-bar convention if this screen ever shows a bar — but onboarding itself should be **chrome-free** (no app bar), to keep it clean and minimal.
- **Note for opencode:** if `dynamic_color` isn't already a dependency in `pubspec.yaml`, add it (`dynamic_color: ^1.7.0` or latest) rather than reintroducing static ColorScheme tokens.
---
 
## 5. Widgets to Create
 
Put shared/reusable widgets in `lib/widgets/shared/`, screen-specific ones in `lib/features/onboarding/widgets/`.
 
### 5.1 `AppTextField` *(shared — check if it already exists first; if not, create it)*
- Location: `lib/widgets/shared/app_text_field.dart`
- M3-styled `TextFormField` wrapper: rounded (16dp) outlined border, label + inline error text slot, consistent padding, colors pulled live from `Theme.of(context).colorScheme.outline` / `.error` (dynamic — see §4).
- Params: `label`, `hintText`, `errorText`, `controller`, `keyboardType`, `autofillHints`, `onChanged`.
- This becomes the canonical text field for the whole app going forward — not onboarding-only.
### 5.2 `PinKeypadField` *(new — onboarding + future login reuse)*
- Location: `lib/widgets/shared/pin_keypad_field.dart`
- Two parts, self-contained in one widget:
  - **Dot indicator row** at top: `kAdminPinLength` circles, filled/animated as digits are entered, shake animation (translate, not color-only) on mismatch/error.
  - **Numeric keypad grid**: 3×4 grid (1–9, blank/0/backspace on last row), M3 filled-tonal buttons, large tap targets (min 56dp) for touch reliability on tablet/mobile. On desktop, also accept physical number-key input.
- Params: `length`, `onChanged(String pin)`, `onCompleted(String pin)`, `hasError`, `label`.
- No system keyboard — this is a custom on-screen keypad only.
### 5.3 `OnboardingSidebar` *(desktop only)*
- Location: `lib/features/onboarding/widgets/onboarding_sidebar.dart`
- Fixed 360dp width, background = `colorScheme.secondaryContainer` (dynamic, shifts with the device palette — see §4), centered Brewline logo + wordmark, short tagline text, rounded outer edge (28dp) on the side facing the content pane. Check logo contrast against `onSecondaryContainer` at build time since the exact hue is no longer fixed.
### 5.4 `OnboardingForm`
- Location: `lib/features/onboarding/widgets/onboarding_form.dart`
- Contains: `AppTextField` (username) → `PinKeypadField` (PIN) → `PinKeypadField` (confirm PIN, revealed once first PIN reaches `kAdminPinLength`) → primary "Finish setup" `FilledButton`.
- Purely presentational; reads/writes via the provider in §6, no business logic inline.
### 5.5 `OnboardingLayout`
- Location: `lib/features/onboarding/widgets/onboarding_layout.dart`
- The responsive shell described in §3, wraps `OnboardingForm`.
---
 
## 6. Files to Create
 
```
lib/
  features/
    onboarding/
      onboarding_page.dart              // entry screen, reads provider state, handles navigation on success
      providers/
        onboarding_provider.dart        // StateNotifier/AsyncNotifier: form state + submit logic
        onboarding_state.dart           // freezed/plain class: username, pin, confirmPin, status, errorMessage
      widgets/
        onboarding_layout.dart
        onboarding_sidebar.dart
        onboarding_form.dart
  widgets/
    shared/
      app_text_field.dart               // create only if it doesn't already exist in the project
      pin_keypad_field.dart
```
 
---
 
## 7. Providers (Riverpod)
 
### `onboardingProvider` — `AsyncNotifierProvider<OnboardingNotifier, OnboardingState>`
 
**State (`OnboardingState`):**
```dart
class OnboardingState {
  final String username;
  final String pin;
  final String confirmPin;
  final String? usernameError;
  final String? pinError;      // e.g. "PIN must be 6 digits"
  final String? confirmError;  // e.g. "PINs don't match"
  final bool isSubmitting;
  final String? submitError;   // e.g. storage failure
}
```
 
**Notifier responsibilities:**
- `setUsername(String)`, `setPin(String)`, `setConfirmPin(String)` — update state, run inline validation per field on change.
- `get isValid` (derived, not stored) — true when username passes rules, pin length == `kAdminPinLength`, confirmPin == pin.
- `submit()` — guards on `isValid`, sets `isSubmitting = true`, hashes the PIN (reuse whatever hashing approach is already standard for this project — do not invent a new one; if none exists yet for Flutter side, use a well-maintained package like `argon2` bindings or, if unavailable on target platforms, `bcrypt`), writes username + hash to local storage (`flutter_secure_storage` for the hash, `sqflite` for the admin record if that mirrors the existing schema), sets `onboarding_complete = true`, then emits a success state for the page to navigate away on.
**Validation rules (assumption — adjust if you have stricter ones already defined):**
- Username: 3–24 chars, letters/numbers/underscore only, no leading/trailing whitespace.
- PIN: exactly `kAdminPinLength` digits, digits only.
- Confirm PIN: must exactly match PIN.
- No "weak PIN" blocklist (e.g. `000000`) is enforced by default — flag this as optional hardening, don't block on it unless you want it.
---
 
## 8. Navigation & Persistence
 
- On successful submit: navigate to the admin dashboard (replace, not push — onboarding should not be reachable via back button afterward).
- Persist an `onboarding_complete` flag (shared prefs or a single-row settings table, whichever the project already uses elsewhere) so app relaunch skips straight to login.
- Never store the raw PIN — only the hash, plus a stored salt if the hashing scheme requires one.
---
 
## 9. Acceptance Checklist
 
- [ ] Renders correctly at 375dp, 768dp, and 1280dp+ widths without overflow
- [ ] Desktop sidebar shows logo + wordmark, does not scroll independently of content
- [ ] Keypad accepts touch and physical keyboard digit input
- [ ] Confirm-PIN step only appears after PIN reaches full length
- [ ] Mismatched PINs show inline error + dot-row shake, do not crash or silently clear
- [ ] "Finish setup" button disabled until `isValid`
- [ ] Submit failure (e.g. storage error) shows inline error, does not lose entered username
- [ ] On success, `onboarding_complete` persists across app restart and onboarding is not shown again
- [ ] All new colors pull live from `Theme.of(context).colorScheme` (dynamic) — no hardcoded hex anywhere except the single `kBrandSeedColor` fallback constant
- [ ] Verified onboarding still looks correct on a device/emulator with dynamic color **unsupported** (fallback seed scheme kicks in cleanly)
- [ ] `AppTextField` and `PinKeypadField` have no onboarding-specific logic baked in — reusable for the future login screen

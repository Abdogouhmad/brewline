# Login Page — Implementation Spec (Brewline / Café POS)
 
**Audience:** opencode coding agent
**Stack:** Flutter (Android + tablet + desktop), Riverpod, `flutter_secure_storage`, `sqflite_common_ffi`, `dynamic_color`
**Design language:** Material 3 Expressive
**Depends on:** `ONBOARDING_UI_SPEC.md` — reuses `AppTextField` and `PinKeypadField` built there. Read that spec first; do not recreate those widgets.
**Status:** Ready for implementation — assumptions flagged below, change if wrong.
 
---
 
## 1. Purpose
 
The login page is the **entry point after onboarding**. It authenticates either:
 
1. The **admin** (single account, created during onboarding), or
2. A **waiter** (account created later by the admin, inside the admin dashboard)
against one shared screen with a role switch, then routes to the matching dashboard. It also owns the **logout** action for both roles, which always returns to this same screen.
 
```
App launch
   → onboarding_complete == false → OnboardingPage
   → onboarding_complete == true  → LoginPage
        → login as admin  → AdminDashboard  --(logout)--> LoginPage
        → login as waiter → WaiterDashboard --(logout)--> LoginPage
```
 
**Out of scope:** waiter account creation/management (lives in the admin dashboard), password recovery, "remember me" persistence (see §9 — session does not survive app restart by default).
 
---
 
## 2. Functional Requirements
 
- One screen, one role switch (Admin / Waiter) — not two separate routes. Switching roles just swaps which form fields/validation apply; it does not navigate.
- Admin credentials are validated against the **real** account created during onboarding (hash comparison).
- Waiter credentials are validated against waiter records in local storage. Since waiter management isn't built yet, **seed dummy waiter accounts** on first run so the flow is testable end-to-end (see §7).
- Successful login creates an in-memory session (role + user id/username) held by `authProvider`, and navigates with `pushReplacement` (never leaves LoginPage on the back stack).
- **Logout** is a single shared action, available from both dashboards, that clears the session and returns to `LoginPage` with the entire navigation stack cleared (`pushAndRemoveUntil`) — the user should never be able to back-button into an authenticated screen after logging out.
---
 
## 3. UX Flow (single screen, no wizard)
 
1. Brand mark (Brewline logo + wordmark) — same treatment as onboarding.
2. **Role switch** at the top of the form: M3 `SegmentedButton<Role>` with two segments, "Admin" and "Waiter". Defaults to whichever role was last used (persist just this preference, not the session — see §9).
3. Username field (`AppTextField`) — label changes contextually: "Admin username" vs "Waiter username".
4. PIN field (`PinKeypadField`, same 6-digit component from onboarding — `kAdminPinLength` for admin, reuse the same constant for waiter unless you later want a shorter staff PIN).
5. Primary button: **"Log in"** — disabled until username + full-length PIN are entered. Do not pre-validate correctness client-side beyond format; wrong credentials are reported after submit.
6. On failure: inline error under the PIN field ("Incorrect username or PIN") — deliberately generic, don't reveal whether the username or the PIN was wrong. Clear the PIN field, keep the username. Shake the PIN dot row (reuse the animation already built into `PinKeypadField`).
7. On success: brief loading state on the button, then navigate.
---
 
## 4. Responsive Layout
 
Reuse the exact structure from onboarding rather than rebuilding it:
 
- Extract the onboarding screen's responsive shell into a shared `AuthScreenLayout` widget (`lib/widgets/shared/auth_screen_layout.dart`) if it isn't already generic — it takes a `formBuilder` slot and renders the compact / medium / expanded variants described in the onboarding spec (single column on mobile, centered card on tablet, fixed sidebar + centered form on desktop ≥905dp).
- `OnboardingPage` and `LoginPage` both consume `AuthScreenLayout` — the sidebar/logo treatment should look like the same app, not two different designs.
- If refactoring the existing onboarding layout is out of scope right now, it's acceptable to duplicate the shell into `LoginLayout` — but flag that as tech debt in a code comment, don't silently diverge the two visual designs.
---
 
## 5. Design System
 
Same dynamic-color setup as onboarding — **do not hardcode hex colors here either.**
 
- Colors come from `Theme.of(context).colorScheme`, generated at runtime via `DynamicColorBuilder` (see `ONBOARDING_UI_SPEC.md` §4 for the full setup). `kBrandSeedColor` (`#3C2A21`, espresso) is the fallback seed only.
- Corner radii: 28dp on cards/sidebar, 16dp on fields, buttons, and the segmented control.
- The role `SegmentedButton` should use `colorScheme.secondaryContainer` for the selected segment — keep it visually distinct from the primary "Log in" button so users don't confuse "pick a role" with "submit."
- Error states use `colorScheme.error` / `onErrorContainer`, consistent with onboarding's PIN mismatch styling.
- Motion: reuse `PinKeypadField`'s existing shake/fill animations as-is — don't reimplement.
---
 
## 6. Widgets to Create
 
### 6.1 `LoginForm`
- Location: `lib/features/auth/widgets/login_form.dart`
- Contains: `SegmentedButton<Role>` → `AppTextField` (username) → `PinKeypadField` (PIN) → `FilledButton` ("Log in"). Purely presentational, reads/writes via `authProvider`.
### 6.2 `RoleSegmentedControl`
- Location: `lib/features/auth/widgets/role_segmented_control.dart`
- Small wrapper around M3 `SegmentedButton<Role>` so the two-segment Admin/Waiter styling is defined once and reused if needed elsewhere (e.g. a future account-switcher).
### 6.3 `LogoutButton` *(shared — used in both dashboards)*
- Location: `lib/widgets/shared/logout_button.dart`
- An `IconButton` (logout icon) meant for an app bar action slot. On tap, shows a small M3 confirm dialog ("Log out?" / Cancel / Log out) before calling `authProvider.logout()` — prevents accidental taps on a shared café device.
- Takes no params beyond an optional `onLoggedOut` callback for screen-specific cleanup (e.g. clearing an in-progress order draft) before navigation fires.
---
 
## 7. Files to Create
 
```
lib/
  core/
    models/
      user_role.dart                  // enum Role { admin, waiter }
  features/
    auth/
      login_page.dart                 // entry screen, wires AuthScreenLayout + LoginForm
      providers/
        auth_provider.dart            // AsyncNotifier: session state, login(), logout()
        auth_state.dart               // session model: role, userId, username, status, errorMessage
        login_form_provider.dart      // local form state: username/pin input + validation (separate from session)
      widgets/
        login_form.dart
        role_segmented_control.dart
  widgets/
    shared/
      logout_button.dart
      auth_screen_layout.dart         // extracted/shared with onboarding, see §4
```
 
---
 
## 8. Providers (Riverpod)
 
### `authProvider` — `AsyncNotifierProvider<AuthNotifier, AuthState?>`
Represents the **current session** (nullable — `null` = logged out). Read by router redirect logic and by both dashboards to know who's logged in.
 
```dart
class AuthState {
  final Role role;
  final String userId;
  final String username;
}
```
 
**Notifier responsibilities:**
- `Future<void> login({required Role role, required String username, required String pin})`
  - Admin: look up the single admin record, hash-compare `pin` against the stored hash from onboarding.
  - Waiter: look up a waiter record by username among seeded/admin-created waiters, hash-compare PIN.
  - On success: set state to the resulting `AuthState`.
  - On failure: throw a typed `AuthException` with a generic message (see §3.6) — do **not** distinguish "user not found" vs "wrong PIN" in what's surfaced to the UI.
- `Future<void> logout()` — clears state to `null`. Does **not** touch the "last used role" preference (§3.2) or any onboarding data.
### `loginFormProvider` — local, screen-only state
Keeps the in-progress username/PIN/role-toggle input separate from the actual session, mirroring the separation used in onboarding's form provider. Reset whenever `LoginPage` is disposed or after a failed attempt clears the PIN.
 
---
 
## 9. Session Behavior & Dummy Credentials
 
**Assumption — no session persistence across app restart.** Every fresh app launch (after onboarding is done) shows `LoginPage`; there is no "stay logged in." This is deliberate for a shared café device — flag it to the user if they'd rather persist the admin session. Only the **last-selected role toggle position** is remembered (e.g. via `shared_preferences`), purely as a UX convenience, not an auth shortcut.
 
**Dummy accounts for testing — seed once, debug-gated:**
 
Seed these automatically the first time the app runs *in debug builds only* (`kDebugMode` check, or a dedicated dev/staging flavor — do not let this ship in a release build):
 
| Role | Username | PIN | Notes |
|---|---|---|---|
| Admin | `admin` | `123456` | Only seeded if no real admin exists yet (i.e. skip if onboarding already ran) — never overwrite a real admin record. |
| Waiter | `waiter1` | `111111` | Seeded into the waiter table so the waiter login path is testable before the admin-side "create waiter" screen exists. |
 
Put the seeding logic in one clearly named place — e.g. `lib/core/dev/dummy_data_seeder.dart` — with a loud top-of-file comment explaining it must never run in release builds. Guard the call site (likely `main.dart`) with `if (kDebugMode) { await seedDummyAccounts(); }`.
 
---
 
## 10. Documentation Requirements
 
Since maintainability was explicitly requested:
 
- Every public class in `features/auth/` and the new shared widgets gets a dartdoc (`///`) comment: one line describing purpose, plus `@param`-style notes for any non-obvious constructor parameter.
- `auth_provider.dart` gets a file-level comment explaining the admin-vs-waiter lookup difference and where the "generic error message" decision is enforced (§3.6) — this is a deliberate security choice, not an oversight, and should read that way to future maintainers.
- `dummy_data_seeder.dart` gets a file-level comment with the exact dummy credentials table from §9, so nobody has to hunt for them during testing.
- No inline comments restating what the code obviously does — comments should explain *why*, matching the rest of the codebase's existing doc style.
---
 
## 11. Acceptance Checklist
 
- [ ] Role switch toggles form context without navigating or losing entered username
- [ ] Admin login succeeds with the real onboarding-created credentials
- [ ] Admin login also succeeds with the seeded dummy admin in a fresh debug install (before onboarding has run for real, if applicable to your test flow)
- [ ] Waiter login succeeds with the seeded dummy waiter (`waiter1` / `111111`)
- [ ] Wrong PIN or unknown username shows the same generic inline error either way
- [ ] Failed attempt clears PIN but keeps username, and shakes the dot row
- [ ] Successful login navigates with the auth stack cleared (back button never returns to LoginPage)
- [ ] Logout from AdminDashboard and from WaiterDashboard both work, both show the confirm dialog, both land back on LoginPage with a clean stack
- [ ] Session does not survive a full app restart (relaunch always shows LoginPage, not an auto-logged-in dashboard)
- [ ] Dummy account seeding is provably excluded from release builds (verify the `kDebugMode`/flavor guard)
- [ ] All colors pulled from `colorScheme`, none hardcoded, consistent with the onboarding page's visual language
- [ ] Dartdoc comments present per §10

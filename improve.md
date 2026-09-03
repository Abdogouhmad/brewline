# Login — PIN-Only Identification (Brewline / Café POS)

**Audience:** opencode coding agent
**Stack:** Flutter, Riverpod, `flutter_secure_storage`, `sqflite_common_ffi`, `dynamic_color`
**Replaces:** the earlier username + PIN login spec. This is a full replacement, not a patch on top — read §1 first if the old version is already implemented.
**Depends on:** `ONBOARDING_UI_SPEC.md` (`PinKeypadField`, `AppTextField`), `ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` (responsive shell pattern).
**Status:** Ready for implementation.

---

## 0. What Changed and Why

Old approach: pick a role (Admin/Waiter), type a username, then enter a PIN.
New approach: **enter a PIN, nothing else.** The system identifies who's logging in — and therefore which role/dashboard they land on — purely from the PIN. No role switch, no username field, no second identifying input at all.

This has one important consequence the request didn't spell out but the system has to handle correctly: **if the only thing you type is a PIN, every PIN in the system must be unique** — across the admin and every waiter, not just unique per role. §3 is entirely about getting that right, because the naive way to enforce it (a database `UNIQUE` constraint on the stored hash) doesn't actually work once PINs are hashed with per-user salts, which is what this project already does. Read that section before touching the database.

---

## 1. Migration Notes (if the old login screen is already built)

Remove:
- `RoleSegmentedControl` widget and any `Role` enum branching in the login form — there's no role choice anymore, the system determines it.
- The username `AppTextField` from the login form specifically (it stays in **onboarding** — the admin's display name is still useful elsewhere, see §5).
- The "last used role" preference that used to default the segmented control — no longer meaningful, delete it rather than leaving dead code.
- The "confirm PIN" step doesn't apply here — that was always onboarding-only, no change needed on that front.

Modify:
- `authProvider.login(...)` — signature changes from `{role, username, pin}` to just `{pin}`. See §4.
- `login_form_provider.dart` — drops `username` and `role` fields entirely, keeps only the in-progress PIN string.

Add:
- A shared PIN-uniqueness check (§3) that needs to be wired into **every** place a PIN gets set or changed — onboarding, waiter creation, waiter PIN reset, and any future admin PIN-change flow. Some of these screens may not have written specs yet in this project; wherever they exist or get built, this validator applies.

---

## 2. Functional Requirements

- One input: a PIN, entered on the same `PinKeypadField` component already built for onboarding — no new keypad widget needed.
- On completing all digits, the app looks up which user (if any) that PIN belongs to, and what role they have.
- No match → generic error, same principle as before but simpler now that there's no username to also be wrong: just **"Incorrect PIN."**
- Match → navigate straight to that user's dashboard (Admin or Waiter), exactly as before — the destination logic doesn't change, only how the app decides who's logging in.

---

## 3. PIN Uniqueness — the Part That Needs Care

### 3.1 Why a `UNIQUE` database constraint doesn't work here
PINs are (and should stay) hashed with a per-user random salt — that's already this project's convention for the admin PIN from onboarding, and it should extend to waiter PINs too. But a salted hash means **the same PIN produces a different stored hash for every user.** Two people who both pick `1234` end up with two completely different-looking hash strings in the database. A `UNIQUE` index on that column would never catch the collision — it would just let both rows exist, silently defeating the whole point of this requirement.

### 3.2 What to do instead
Enforce uniqueness in application code, by checking a *candidate* PIN against every existing user's hash at the moment it's being set — not by indexing the stored hash.

```dart
/// Returns true if [candidatePin] matches any existing active user's PIN.
/// [excludingUserId] lets a user's own unchanged PIN pass during an edit
/// (otherwise editing a waiter without changing their PIN would flag
/// itself as a duplicate).
Future<bool> isPinTaken(String candidatePin, {int? excludingUserId}) async {
  final users = await userRepository.getAllActiveUsers(); // admin + waiters
  for (final user in users) {
    if (excludingUserId != null && user.id == excludingUserId) continue;
    if (await PinHasher.verify(candidatePin, user.pinHash)) return true;
  }
  return false;
}
```

Call this **before** writing a new hash, everywhere a PIN is set:
- Onboarding's PIN step (trivial the very first time — no other users exist yet — but wire it in now so the pattern is already correct if onboarding is ever re-run, e.g. a factory-reset flow).
- Waiter creation.
- Waiter PIN reset/edit.
- Any future "change my PIN" flow in admin settings.

If it returns `true`, surface a clear inline error at the point of entry ("That PIN is already in use — pick a different one") rather than a generic failure — this one specifically *should* say what's wrong, unlike login errors, because the person setting the PIN is authorized to know why it was rejected.

### 3.3 Login lookup uses the same scan
Identifying who's logging in works the same way, in reverse — there's no username to look up a single row first, so the login check scans active users and verifies the entered PIN against each stored hash until one matches:

```dart
Future<User?> findUserByPin(String pin) async {
  final users = await userRepository.getAllActiveUsers();
  for (final user in users) {
    if (await PinHasher.verify(pin, user.pinHash)) return user;
  }
  return null;
}
```

Both `isPinTaken` and `findUserByPin` should live in one place (`lib/core/auth/pin_lookup.dart` or similar) and be the **only** code that ever scans+verifies PINs — don't duplicate this loop in the login provider and the waiter-form provider separately.

### 3.4 Performance note — read before assuming this needs optimizing
This scan runs the hash-verify function once per active user, which sounds worse than it is: for a café's actual staff size (a handful up to maybe 20), a handful to twenty argon2 verifies is comfortably sub-second — not something a real user will perceive as slow. If staff count ever grows into the dozens+, this cost scales linearly and is worth revisiting (e.g. a faster-but-still-salted hash tuned specifically for this lookup path), but don't pre-optimize for a scale this app isn't at. This is a deliberate simplicity-over-premature-optimization choice, not an oversight — a deterministic pepper-based lookup hash would make this an indexed O(1) lookup, but it adds a second hash column and a secret-management burden that isn't worth it at café scale, and doesn't meaningfully change the real security picture anyway (see §3.5).

### 3.5 Honest note on what a 6-digit PIN actually protects against
Worth being upfront about: a 6-digit PIN has exactly 1,000,000 possible values — trivially brute-forceable offline by anything faster than "a human tapping buttons," regardless of how strong the hashing algorithm is. The realistic threat model here isn't "attacker with the database file," it's "someone physically at the till trying PINs by hand" — which is what §6's optional throttle is actually defending against, not cryptographic strength. Keep the salted hashing (it's still correct practice and cheap to keep), just don't treat it as the main defense.

---

## 4. `authProvider` Changes

```dart
Future<void> login({required String pin}) async {
  final user = await pinLookup.findUserByPin(pin);
  if (user == null) {
    throw AuthException('Incorrect PIN'); // generic, same principle as before
  }
  state = AuthState(role: user.role, userId: user.id, username: user.displayName);
}
```

Everything downstream — session state shape, `logout()`, no-persistence-across-restart behavior, the "last used role" removal aside — is unchanged from the original login spec.

---

## 5. What Happens to "Username"

The username field is **not removed from the data model** — it's removed only from the *login* form. Keep it as each user's display name:
- Shown in receipts ("Served by: Maria"), the Sales Log and Cashout Logs "Waiter" column, and anywhere else a human-readable name matters — all of that already depends on it existing.
- Still collected in onboarding (admin's own display name) and in waiter creation (wherever that screen lives).
- Cosmetic-only suggestion, not required: consider relabeling it "Name" instead of "Username" in UI copy wherever it's shown, since "username" now implies a login role it no longer has — but don't rename the underlying database column just for this, that's a migration for no functional gain.

---

## 6. Optional Hardening: Attempt Throttling

Worth adding given §3.5 — not required, but cheap and meaningfully raises the bar against someone standing at the till trying PINs by hand:

- Track consecutive failed attempts **in memory** (no database table needed — this resets naturally on app restart, which is fine for this threat model).
- After 5 consecutive failures, disable the keypad for a short cooldown (e.g. 15–30 seconds) with a visible countdown, rather than silently rejecting input.
- Reset the counter on any successful login.
- This is a UX/deterrence measure, not a cryptographic one — keep the existing generic "Incorrect PIN" message throughout, don't let the lockout messaging reveal anything about which PINs are close to correct.

---

## 7. Files Changed

```
lib/
  core/
    auth/
      pin_lookup.dart              // NEW — isPinTaken() + findUserByPin(), the only PIN-scan logic in the app
    database/
      repositories/
        waiter_repository.dart     // MODIFIED — waiter create/edit now calls isPinTaken() before writing a hash
  features/
    auth/
      login_page.dart              // MODIFIED — no role toggle, single PinKeypadField, auto-submits on completion
      providers/
        auth_provider.dart         // MODIFIED — login({pin}) instead of login({role, username, pin})
        login_form_provider.dart   // MODIFIED — drops username/role state
      widgets/
        login_form.dart            // MODIFIED — role toggle and username field removed
        role_segmented_control.dart  // DELETE — no longer used anywhere
  features/
    onboarding/
      providers/
        onboarding_provider.dart   // MODIFIED — PIN step now also calls isPinTaken() (see §3.2)
```

---

## 8. Documentation Requirements

- `pin_lookup.dart` gets a file-level comment explaining §3.1–§3.2 in full — specifically *why* there's no database `UNIQUE` constraint doing this work, so a future maintainer doesn't "helpfully" add one and assume it's covering a case it can't actually catch.
- `auth_provider.dart`'s doc comment updates to reflect the simplified single-parameter `login()` — remove any stale reference to role-based lookup.
- Any screen that sets or changes a PIN gets a one-line comment noting it calls `isPinTaken()` before persisting, so the requirement doesn't silently get skipped in a future waiter-management screen someone builds without re-reading this spec.

---

## 9. Acceptance Checklist

- [ ] Login screen shows only a PIN keypad — no role toggle, no username field
- [ ] Entering a full PIN auto-submits (no separate "Log in" button needed) and routes to the correct dashboard based on the matched user's role
- [ ] Wrong/unrecognized PIN shows a generic "Incorrect PIN" message and shakes the dot row, same animation as before
- [ ] Onboarding's admin PIN step calls `isPinTaken()` before writing the hash
- [ ] Waiter creation/edit calls `isPinTaken()` before writing a hash, and correctly excludes the waiter's own current PIN when editing without changing it
- [ ] Attempting to set a duplicate PIN anywhere shows a specific "That PIN is already in use" error, not a generic failure
- [ ] No `UNIQUE` constraint was added on any PIN-hash database column — confirm the enforcement is application-level per §3.2
- [ ] Display names (formerly "username") still show correctly on receipts, Sales Log, and Cashout Logs — confirming removal from the login form didn't remove the underlying data
- [ ] `RoleSegmentedControl` and the "last used role" preference are fully deleted, not just unused
- [ ] (If implemented) attempt throttling locks out input after 5 consecutive failures and recovers automatically after the cooldown

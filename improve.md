# OTA Update System — Implementation Plan (Brewline / Café POS)

**Audience:** opencode coding agent
**Stack:** Flutter, Riverpod, Android (phones + tablets)
**Depends on:** `ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` (Settings page already exists, hosts logout + printer settings — this adds one more section there).
**Status:** Ready for Phase 1 implementation. Phase 2 is a real option, not a requirement — see §7 before building it.

---

## 0. Why this shape

This app isn't distributed through the Play Store — it's sideloaded onto a small number of café-owned devices. That changes what "OTA update" should mean here versus a typical consumer app:

- No app-store review to route around, so there's no need for a Shorebird/CodePush-style tool as the *primary* mechanism — a plain, self-hosted "check → download → install new APK" flow does the whole job, costs nothing recurring, and you fully own it (consistent with this project's zero-recurring-cost, own-the-stack approach throughout).
- It has to be honest about being offline-first: an update check must never block app startup or normal café operation, and a failed/absent check should be silent, not an error state the waiter or admin has to deal with mid-shift.
- It lives in **Settings**, admin-facing only — waiters never see update UI.

**Two phases:**
1. **Phase 1 (this spec, build now):** full-APK OTA — check a small manifest, download the new APK, hand off to Android's installer. Covers every kind of change (Dart code, native plugins, schema migrations) because it's a real new build, not a patch.
2. **Phase 2 (optional, later):** a fast "hot-patch" layer for small Dart-only fixes between full releases, so you're not rebuilding/re-signing/re-distributing a whole APK for a one-line bug fix. Two real candidates exist for this, compared in §7 — deliberately not chosen for you here, since it's an architecture decision worth making with eyes open rather than inheriting a default.

---

## 1. ⚠️ Read before building: the signing-key risk

This is the one mistake that can silently destroy a café's data, so it goes first, not in a footnote.

**Every release APK must be signed with the same, stable release keystore, forever.** Android refuses to install an update over an existing app if the signature doesn't match the one already installed — it forces an *uninstall first*, which wipes the app's local SQLite database (all orders, products, shifts, everything, since this is offline-first local storage). If you ever lose the keystore or accidentally build a release with the debug key, the next "update" silently becomes a full data-loss event for whichever café is running it.

Do this once, before Phase 1 ships to a real device:
- Generate one release keystore (`keytool -genkey ...`), store it **outside the repo**, back it up in at least two places (e.g. a password manager + an encrypted offline copy).
- Configure `android/app/build.gradle` to sign release builds with it via `key.properties` (kept out of version control, `.gitignore`'d).
- Every future `flutter build apk --release` for distribution must use this same keystore. Document this loudly in the repo's README, not just here.

---

## 2. Update Manifest

A small JSON file, hosted for free on GitHub (a release asset or a raw file in the repo) — no server to run, no recurring cost.

```json
{
  "latestVersionCode": 14,
  "latestVersionName": "1.4.0",
  "minSupportedVersionCode": 10,
  "mandatory": false,
  "releaseNotes": "- Added refund system\n- Fixed cashout report totals",
  "apkUrl": "https://github.com/Abdogouhmad/brewline/releases/download/v1.4.0/brewline-v1.4.0.apk",
  "apkSha256": "<sha256 of that exact apk file>",
  "publishedAt": "2026-09-01T00:00:00Z"
}
```

- `latestVersionCode` — plain integer, compared against the installed app's Android version code (`PackageInfo.buildNumber`). Simple integer comparison, no semver parsing needed on-device.
- `minSupportedVersionCode` — a safety valve: if the installed app is older than this, treat the update as **mandatory** even if `mandatory` is `false`, e.g. for a release that fixes a serious bug or incompatible data issue.
- `apkSha256` — computed at build time, verified on-device after download, before install is ever offered. This matters more than usual here since there's no Play Store doing that verification for you.

**Optional automation (not required for Phase 1):** a GitHub Actions workflow triggered on a version tag that runs `flutter build apk --release`, computes the SHA-256, creates a GitHub Release with the APK attached, and updates `update_manifest.json`. Worth doing once the manual flow is working and proven — don't build this before the manual version works.

---

## 3. App-Side Flow

### 3.1 Package
Use `ota_update` (or a current equivalent — check pub.dev for the latest maintained fork before locking it in, this space moves fast) for the actual download+verify+install mechanics: it streams download-progress events, verifies the `sha256checksum` you pass in, and hands off to Android's `PackageInstaller` — you don't hand-roll any of that.

Android manifest additions:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>
```
On first use, Android will prompt the user to grant "Install unknown apps" for this app if it isn't already — that's expected and only happens once per device.

### 3.2 Files
```
lib/
  core/
    updates/
      update_manifest.dart     // model: UpdateManifest.fromJson(...)
      update_service.dart      // fetchManifest(), compare vs PackageInfo, decide mandatory/optional/none
      update_provider.dart     // Riverpod: idle / checking / available / downloading(progress) / readyToInstall / error
  features/
    settings/
      widgets/
        update_section.dart          // "App Updates" block inside the existing Settings page
        update_action_sheet.dart     // responsive: dialog (desktop) / bottom sheet (mobile+tablet) — release notes + download progress + install
        update_required_screen.dart  // full-screen, non-dismissible — only shown for mandatory updates
```

### 3.3 `update_service.dart`
- `Future<UpdateCheckResult> checkForUpdate()`:
  1. `GET` the manifest URL with a short timeout (~6s).
  2. On any failure (offline, timeout, malformed JSON) — return a "check failed, stay quiet" result. **Never throw an error the user sees for a background check.** This app is offline-first; not being able to reach GitHub is a normal, unremarkable state, not a bug.
  3. Compare `manifest.latestVersionCode` against the installed `PackageInfo.buildNumber`.
  4. Return one of: `upToDate`, `updateAvailable(manifest)`, `updateMandatory(manifest)` (the last one if `mandatory == true` or installed version < `minSupportedVersionCode`), or `checkFailed`.

### 3.4 `update_section.dart` (in Settings)
- Shows current version: `"Version 1.3.2 (build 13)"`.
- "Check for Updates" button — manual trigger, shows a small spinner while checking.
- Toggle: **"Check automatically on launch (Wi-Fi only)"** — off by default is a reasonable start; if on, use `connectivity_plus` to confirm Wi-Fi before checking, and run the check a few seconds *after* launch, never blocking startup.
- "Last checked: 2 hours ago" — small, muted text, for transparency.
- If a check finds an update: a small badge/dot on this section (and optionally on the Settings nav destination itself, if you want the nav shell from the admin dashboard spec to expose that — flagged as optional polish, not required).

### 3.5 `update_action_sheet.dart`
Same responsive pattern already established for the refund action UI (`REFUND_SYSTEM_SPEC.md` §5) — reuse that split, don't reinvent it:
- **Desktop:** `showDialog`, fixed width (~480dp).
- **Mobile/tablet:** `showModalBottomSheet`, rounded top corners (28dp), draggable.

Content:
1. "Update available — v1.4.0" header.
2. Release notes rendered as a simple bulleted list (split the manifest's `releaseNotes` string on newlines/leading `-`).
3. "Download & Install" button → starts `OtaUpdate().execute(...)`, button becomes a determinate progress bar (`colorScheme.primary`) with a percentage label as download events stream in.
4. On checksum failure or network error mid-download: show a clear error and a "Retry" button — never leave the user staring at a stalled progress bar with no explanation.
5. On success, the package hands off to Android's own install confirmation screen — that's a system UI, not something to theme; the app's job ends at handing off the verified APK.

### 3.6 `update_required_screen.dart`
Only shown when `checkForUpdate()` returns `updateMandatory`. Full-screen, no back button, no dismiss — just the release notes and a single "Download & Install" action. This should be rare (reserved for genuinely breaking changes) — don't set `mandatory: true` casually in the manifest, since it blocks the admin from using the app at all until they update.

---

## 4. State & Persistence

No new database table needed — this is small enough for `shared_preferences`:
- `last_update_check_at` — timestamp, powers the "Last checked" label.
- `auto_check_enabled` — the Settings toggle from §3.4.
- `dismissed_version_code` — if the admin dismisses an *optional* update prompt, don't re-surface the same version automatically on every future auto-check; still show it if they manually tap "Check for Updates," and always re-surface for any *newer* version code.

---

## 5. Multi-Device Reality Check

Each café device (phone/tablet) sideloads and updates independently — there's no fleet-push here without adding real infrastructure (MDM, etc.), which is out of scope for a single-café tool. Each device's admin needs to tap through the update flow once per device, per release. Worth knowing going in so it's not a surprise later: this is a "check per device" model, not a "push to everyone at once" model.

---

## 6. Documentation Requirements

- `update_service.dart` gets a file-level comment explaining the fail-silent behavior for background checks (§3.3 step 2) — so a future edit doesn't "helpfully" turn a failed background check into a visible error.
- The repo's top-level README gets a **Release Process** section covering: the keystore requirement from §1, how to bump `latestVersionCode`/`latestVersionName`, how to compute and set `apkSha256`, and where the manifest is hosted. This is operational knowledge that needs to survive outside any one chat/spec.
- `update_manifest.dart` documents each field's meaning, especially `minSupportedVersionCode` vs `mandatory` (they can both make an update mandatory, for different reasons).

---

## 7. Phase 2 (optional, decide before building): fast Dart-only hotfixes

Phase 1 covers every kind of update but always means a full APK download + Android's install prompt — fine for real releases, heavier than you'd want for a one-line bug fix. If that friction becomes annoying, there are two real options for a lighter "patch" layer. Not building either now — just laying out the trade-off so it's a deliberate choice later, not a default:

| | **Shorebird Code Push** | **flutter_patcher** (self-hosted) |
|---|---|---|
| Hosting | Shorebird's cloud | Your own storage/CDN (e.g. same GitHub Releases setup as Phase 1) |
| Cost | Free tier for small/hobbyist use, paid tiers beyond that | Free (MIT-licensed), you host it |
| Maturity | Established, used in production by other teams | Very new — verify current state before relying on it |
| Platforms | Android + iOS (+ desktop) | Android only |
| What it patches | Dart code only, via a modified engine | Dart AOT code + assets |
| Fits this project's "zero recurring cost, own the stack" pattern? | Partially — free tier works, but it's still a third-party cloud dependency | Very well in principle, but weigh that against its youth as a project |

If/when you want this, it slots in cleanly alongside Phase 1: Phase 1 stays the mechanism for real releases (schema changes, new native deps, big features), and whichever Phase 2 tool you pick becomes the mechanism for small in-between fixes only. Flag it and this can become its own spec once you've decided which one.

---

## 8. Acceptance Checklist

- [ ] Release keystore exists, is backed up outside the repo, and `build.gradle` is configured to always sign release builds with it (§1)
- [ ] `update_manifest.json` is reachable at a stable URL and matches the shape in §2
- [ ] Manual "Check for Updates" in Settings correctly reports up-to-date / update-available / check-failed states
- [ ] A failed/offline check never shows an error to the user and never blocks app usage
- [ ] Optional auto-check (Wi-Fi only) runs a few seconds after launch, not during startup
- [ ] Update dialog (desktop) / bottom sheet (mobile+tablet) shows release notes and a working download progress bar
- [ ] Downloaded APK's SHA-256 is verified before Android's install prompt is triggered; mismatches show a retry, not a silent failure
- [ ] Mandatory update screen (`minSupportedVersionCode` or `mandatory: true`) is non-dismissible and blocks normal app use until updated
- [ ] Dismissing an optional update doesn't re-nag for the same version code on the next auto-check, but does surface again for a newer version
- [ ] README's Release Process section is written and accurate (§6)

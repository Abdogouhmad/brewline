# OTA Update System — Implementation Plan (Brewline / Café POS)

**Audience:** opencode coding agent
**Stack:** Flutter, Riverpod — targets **Android** (phones/tablets), **Linux**, and **Windows**
**Depends on:** `ADMIN_DASHBOARD_IMPROVEMENTS_SPEC.md` (Settings page, responsive shell), `REFUND_SYSTEM_SPEC.md` §5 (the dialog/bottom-sheet responsive pattern reused here).
**Status:** Ready for implementation. Revision of the earlier Android-only plan — now covers all three targets with one architecture. Read §0 for what changed and why.

---

## 0. What Changed From the Android-Only Version

The goal, restated precisely: **notify the admin inside the app when an update exists, and let them download + install it without leaving the app**, on Android, Linux, and Windows alike. That "stays inside the app, looks like the rest of the app" requirement is the deciding factor for every choice below — it rules out purely OS-driven update flows (Windows' native MSIX/App Installer auto-update, Linux's AppImageUpdate) as the *primary* mechanism, because those hand the UX over to the operating system's own dialog, not yours. They're mentioned as native alternatives where relevant, but not chosen as the default, for that reason.

What stays the same as before: one JSON manifest, hosted free on GitHub, checked in the background without ever blocking startup, verified by checksum before anything is installed, and surfaced through the same responsive dialog/bottom-sheet shell already used for refunds.

What's new: a **platform handler abstraction** (the update-mechanics equivalent of the `PrinterTransport` interface from the cashout/printing spec — same pattern, same reasoning: one shared interface, one implementation per platform, callers never touch platform specifics directly), and real desktop-specific install mechanics for Windows and Linux.

---

## 1. ⚠️ Read First: Platform-Specific Update Risks

- **Android (unchanged, still the sharpest risk):** every release APK must be signed with the same stable release keystore, forever. A mismatched signature forces Android to uninstall before "updating," which wipes the local SQLite database. See the full explanation and backup checklist already written for this — don't skip it.
- **Windows:** an unsigned `.exe` will trigger a Windows SmartScreen warning ("Windows protected your PC") on first run of *each new version*, since it has no code-signing certificate behind it. This is a friction/trust issue, not a data-loss issue — nothing gets wiped, the admin just has to click "More info → Run anyway" once per release. A paid code-signing certificate removes this, but isn't required to ship; treat it as a future nice-to-have, not a blocker (flagged again in §5.3).
- **Linux:** no signature-matching or store gatekeeping to worry about, but the replacement binary needs its executable bit restored after download/extraction (`chmod +x`), or the app simply won't launch after an update — an easy thing to silently get wrong.

None of the desktop risks are as severe as the Android keystore one, but all three are exactly the kind of thing that's invisible until the first real release goes out — worth testing deliberately, not just trusting the happy path.

---

## 2. Unified Update Manifest

One JSON file, one hosting location, with a section per platform — the app only ever reads the section matching the device it's running on:

```json
{
  "channel": "stable",
  "android": {
    "latestVersionCode": 14,
    "latestVersionName": "1.4.0",
    "minSupportedVersionCode": 10,
    "mandatory": false,
    "apkUrl": "https://github.com/<you>/brewline/releases/download/v1.4.0/brewline-v1.4.0.apk",
    "sha256": "<sha256 of the apk>"
  },
  "windows": {
    "latestVersion": "1.4.0",
    "minSupportedVersion": "1.2.0",
    "mandatory": false,
    "archiveUrl": "https://github.com/<you>/brewline/releases/download/v1.4.0/brewline-windows-v1.4.0.zip",
    "sha256": "<sha256 of the zip>"
  },
  "linux": {
    "latestVersion": "1.4.0",
    "minSupportedVersion": "1.2.0",
    "mandatory": false,
    "archiveUrl": "https://github.com/<you>/brewline/releases/download/v1.4.0/brewline-linux-v1.4.0.tar.gz",
    "sha256": "<sha256 of the tar.gz>"
  },
  "releaseNotes": "- Added refund system\n- Fixed cashout report totals",
  "publishedAt": "2026-09-01T00:00:00Z"
}
```

- `releaseNotes` and `publishedAt` are shared across platforms (same release, same notes) — no need to duplicate them per section.
- Android keeps its integer `versionCode` comparison (matches `PackageInfo.buildNumber`). Windows/Linux compare semantic version strings (`pub_semver` package — already a transitive dependency of most Flutter tooling, safe to add directly) against `PackageInfo.version`.
- Same `mandatory` / `minSupportedVersion(Code)` escape hatch on every platform, same meaning as before: forces the non-dismissible full-screen update-required flow.
- `channel` is new — see §2.1. It's what your production café devices should always be pinned to (`"stable"`).

### 2.1 Bug Fix: Pre-releases Not Being Detected

**Root cause:** if the update checker ended up calling GitHub's REST API directly — specifically the `GET /repos/{owner}/{repo}/releases/latest` endpoint — that endpoint **excludes pre-releases by design.** GitHub only returns the newest release that is *not* flagged as a pre-release and *not* a draft from that endpoint. So any build tagged as a GitHub "pre-release" was always going to be invisible to a checker calling `/releases/latest`, no matter how the version-comparison logic was written — the release simply never showed up in the response at all.

**The actual fix has two parts, and they're independent — do both:**

1. **Stop letting the update checker call the GitHub Releases API directly at all.** This project's manifest-based design (§2) exists specifically so the app never has to reason about GitHub's release semantics — it just reads a JSON file whose meaning you fully control. If the current implementation drifted from that (calling `/releases/latest` or similar instead of fetching `update_manifest.json`), that drift is the bug — move it back onto the manifest. This also sidesteps GitHub's unauthenticated API rate limit (60 requests/hour, shared across every café device checking from the same network), which a direct-API approach would eventually hit and a static manifest fetch never will.
2. **Add an explicit `channel` field** so "does this build show up as an update" is something you set on purpose, not something that depends on which GitHub API endpoint happens to notice it:
   - `"stable"` — only real, finished releases. This is what every café production device should be pinned to.
   - `"beta"` — includes pre-release/test builds, for your own testing devices only.
   - The manifest published for the `beta` channel can point at a pre-release GitHub build; the `stable` manifest only ever points at a normal, fully-published release. Keep them as **two separate manifest files** (e.g. `update_manifest.json` and `update_manifest_beta.json`) rather than one file with a flag, so a café device can never accidentally pull a beta build just because a config value got flipped.
   - `update_service.dart` reads whichever manifest URL matches the build's configured channel (a compile-time constant or a build flavor, not something toggleable from the Settings UI on a production device — beta opt-in shouldn't be reachable by café staff).

If you don't actually need a beta channel at all — if the real ask is simply "stop marking releases as pre-release on GitHub" — that's the simpler fix: just publish every release as a normal (non-pre-release) GitHub Release from now on, and skip the two-manifest setup in point 2 entirely, keeping the single `stable` manifest from before. Worth deciding which of these you actually want before opencode builds it — they're genuinely different setups, not two phrasings of the same thing.

---

## 3. Platform Handler Abstraction

```
lib/core/updates/
  update_manifest.dart          // model: parses the multi-platform JSON above
  update_service.dart           // fetches manifest, picks the right platform section, compares versions
  update_provider.dart          // Riverpod: idle / checking / available / downloading(progress) / readyToInstall / error
  update_installer.dart         // abstract class UpdateInstaller { Future<void> download(...); Future<void> install(); }
  android_update_installer.dart // implements UpdateInstaller via `ota_update` — unchanged from the Android-only plan
  desktop_update_installer.dart // implements UpdateInstaller for Windows + Linux, see §4
```

`update_service.dart` picks the installer at runtime via `Platform.isAndroid` / `Platform.isWindows` / `Platform.isLinux` — every other file (the Settings UI, the action sheet) talks only to `UpdateInstaller`, never to `ota_update` or any desktop-specific package directly. This is the same shape as `ReceiptPrinterService` talking to `PrinterTransport` instead of USB/network specifics — keep that consistency deliberate, it's already this project's established pattern for exactly this kind of "one interface, swappable mechanics" problem.

---

## 4. Desktop Install Mechanics (Windows + Linux)

### 4.1 Recommended approach: a pure-Dart cross-platform updater package
Rather than hand-rolling the download → verify → extract → relaunch sequence twice (once per OS), use a pure-Dart package built for exactly this — no native code, genuinely cross-platform including Linux (unlike Sparkle/WinSparkle-based options, which are Windows+macOS only and would leave Linux with nothing). Look for a current, actively maintained package along these lines before locking in a specific one — the desktop-auto-update space for Flutter is young and still shifting, so verify recent commits/issues rather than trusting a name from this spec alone. What to look for specifically:
- Verified releases (checksum, ideally SHA-256, checked before anything is installed).
- Support for GitHub as a plain hosting provider (no need for a dedicated update server).
- A built-in or themeable UI hook, so it can sit inside the same action-sheet UI from §5 rather than showing its own unrelated banner.

### 4.2 What it does conceptually (useful even if you end up hand-rolling it)
1. Download the platform's archive (`archiveUrl`) to a temp location.
2. Verify its SHA-256 against the manifest before touching anything currently installed.
3. Extract it to a fresh, versioned directory alongside the current install (not on top of it — never overwrite a running app's own files while it's running).
4. On the admin's confirmation to finish, relaunch: spawn the new version's executable, then exit the current process. The next launch reads from the new versioned directory.
5. Optionally prune old versioned directories after a successful relaunch, keeping the last one as a rollback fallback rather than deleting immediately.

### 4.3 Windows specifics
- Ship a `.zip` of the Flutter Windows build output (the whole `Release/` bundle — exe + required DLLs + data folder), not a bare `.exe` — Flutter Windows apps aren't single-file.
- SmartScreen warning on first run of a new version — see §1. If this becomes a real problem for the café's day-to-day comfort, a code-signing certificate is the fix, but that's a paid, recurring cost, which cuts against this project's zero-recurring-cost pattern — worth weighing deliberately rather than defaulting into it.
- **Native alternative, not chosen as default:** MSIX packaging + an `.appinstaller` manifest gets you OS-level, Store-quality auto-update (via Windows' built-in App Installer, checking on a schedule you configure) with no custom download/relaunch code to maintain at all. The trade-off is real: it's the operating system's own update UI, not something themed to match this app, and it needs a code-signing certificate (self-signed is workable for a handful of café-owned devices, but each device has to be told to trust it once). Worth reconsidering if the in-app requirement ever relaxes — flag it back rather than assuming.

### 4.4 Linux specifics
- Ship a `.tar.gz` of the Flutter Linux build bundle (`bundle/` — executable + `lib/` + `data/`).
- Restore the executable bit after extraction (`chmod +x`) — a silent, easy-to-miss failure mode, called out in §1.
- If a desktop entry (`.desktop` file / app menu shortcut) exists, make sure it points at a stable launcher path (e.g. a `current` symlink that gets repointed at the new versioned directory on relaunch) rather than a version-specific path that breaks every release.
- **Native alternative, not chosen as default:** distributing as an AppImage with AppImageUpdate/zsync gives efficient, Linux-native delta updates, but again hands the update UX to an external tool rather than this app's own UI, and adds a packaging format decision (AppImage vs. plain tarball) this plan doesn't otherwise need to make.

---

## 5. Settings UI — Now Shared Across All Three Platforms

The good news: very little new UI is actually needed. The responsive shell from the refund spec already splits on `ScreenSize`, not on platform — and a desktop window (Windows/Linux) naturally lands in the `expanded` breakpoint, an Android phone in `compact`/`medium`. So the exact same `update_action_sheet.dart` (dialog on expanded, bottom sheet on compact/medium) already does the right thing on every platform with no extra branching. Reuse it as-is rather than building a separate desktop update UI.

```
lib/features/settings/widgets/
  update_section.dart          // unchanged in shape: current version, "Check for Updates", auto-check toggle, last-checked label
  update_action_sheet.dart     // unchanged shell; content now driven by whichever UpdateInstaller is active
  update_required_screen.dart  // unchanged: full-screen, non-dismissible, for mandatory updates on any platform
```

One addition worth making: show the platform name/icon next to the version number in `update_section.dart` ("Version 1.4.0 (Windows)" / "... (Android)") — small, but useful once the same admin might be looking at this screen across a phone and a front-counter desktop machine and wants to be sure which build they're looking at.

### 5.1 UI Polish for the Update Action Sheet
A few concrete upgrades to `update_action_sheet.dart`, since "notify + update within the app" is the whole point of this feature and the sheet is where that impression is made:
- Replace a flat linear progress bar with a determinate circular or segmented progress indicator showing the live percentage as a number, not just a moving bar — more legible at a glance, and matches M3 Expressive's more tactile motion language used elsewhere in this app.
- Render `releaseNotes` as an actual bulleted list widget (split on newlines), not a raw text block — small thing, reads much better.
- Distinct success state: a brief checkmark/confirmation animation before handing off to install, rather than the sheet just disappearing — gives the admin a clear "this worked" moment.
- If a beta channel (§2.1) is in use, show a small "Beta" chip/badge in the sheet header on beta-channel builds, so it's never ambiguous which kind of build someone is looking at.
- Distinct, non-alarming styling for the error state (checksum mismatch, network drop) — `colorScheme.errorContainer` background on the message, not a jarring red flash, consistent with how errors are handled elsewhere in this app (e.g. the refund form's validation errors).

---

## 6. Version Comparison Logic

- **Android:** integer `versionCode` comparison, unchanged from the original plan — simplest and matches Android convention.
- **Windows/Linux:** semantic version string comparison via `pub_semver`'s `Version.parse(...)` and its built-in comparison operators — don't hand-roll string/number parsing for this, it's exactly what that package is for and it's already a common transitive dependency in the Flutter ecosystem.
- Both paths funnel into the same `UpdateCheckResult` enum (`upToDate` / `updateAvailable` / `updateMandatory` / `checkFailed`) from the original plan — the comparison mechanics differ, the result shape and everything downstream of it doesn't.

---

## 7. File Structure (full picture, replacing the Android-only version)

```
lib/
  core/
    updates/
      update_manifest.dart          // now parses the "channel" field too
      update_service.dart           // fetches the manifest matching the build's configured channel — never calls the GitHub API directly
      update_provider.dart
      update_installer.dart
      android_update_installer.dart
      desktop_update_installer.dart
  features/
    settings/
      widgets/
        update_section.dart
        update_action_sheet.dart    // polished per §5.1
        update_required_screen.dart
```

---

## 8. Documentation Requirements

- `update_installer.dart` gets a file-level comment explaining the platform-handler pattern and pointing back at `PrinterTransport` as the precedent for this project's "one interface, per-platform implementation" convention — so it reads as consistent architecture, not a one-off.
- `desktop_update_installer.dart` documents the "extract to a fresh versioned directory, never overwrite in place" rule from §4.2 step 3, and why (a partially-overwritten running app is a much worse failure mode than a failed download).
- The repo README's Release Process section (already planned in the Android-only version) now documents building and hashing **three** artifacts per release — APK, Windows zip, Linux tar.gz — not just one, plus the Windows SmartScreen and Linux `chmod +x` notes from §1 so they don't get rediscovered the hard way on release day.

---

## 9. Acceptance Checklist

**Shared**
- [ ] One manifest URL serves all three platform sections; each platform reads only its own section
- [ ] A failed/offline check is silent on every platform — never blocks startup, never surfaces as an error for a routine background check
- [ ] Mandatory-update screen works identically (non-dismissible, blocks app use) regardless of platform
- [ ] The same `update_action_sheet.dart` renders correctly as a dialog on desktop and a bottom sheet on Android, with no platform-specific branching in that file

**Pre-release fix (§2.1)**
- [ ] Confirmed the update checker no longer calls any GitHub Releases API endpoint directly — it only ever fetches the static manifest JSON
- [ ] A build published as a GitHub pre-release, on the `beta` manifest, is correctly detected as an available update on a device configured for the beta channel
- [ ] A production/stable-channel build never picks up a beta manifest, even if one exists at a guessable URL
- [ ] Decided and documented which of the two fixes from §2.1 you're actually using (channel system vs. simply not marking releases as pre-release) — don't leave both half-implemented

**Android**
- [ ] Release keystore requirement from the original plan still holds — re-verify it's actually wired into the build, not just documented
- [ ] APK download, checksum verification, and install handoff work as originally spec'd

**Windows**
- [ ] Downloaded zip is verified by checksum before extraction
- [ ] New version extracts to its own versioned folder, app relaunches into it cleanly, old version is not deleted until the new one has launched successfully at least once
- [ ] First run of a newly installed version is tested against a real (non-dev-machine) Windows install to confirm the SmartScreen prompt is expected/acceptable, not a silent block

**Linux**
- [ ] Downloaded tar.gz is verified by checksum before extraction
- [ ] Executable bit is confirmed present after extraction, on a clean test rather than a machine where it happened to already be set
- [ ] Any desktop entry/launcher shortcut still resolves correctly after an update (i.e. it points at a stable path, not a version-specific one that just broke)

**Docs**
- [ ] README Release Process section covers all three artifacts, not just the Android one

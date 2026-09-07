# Bug Fix: Desktop Launch Crash & Missing Windows Trust Metadata (Brewline / Café POS)

**Audience:** opencode coding agent
**Stack:** Flutter, `sqflite_common_ffi`, targets Android + Linux + Windows
**Status:** Two unrelated issues, evidenced by the screenshots — fixed separately, don't conflate them. Issue A is a real crash and is the priority; Issue B is cosmetic/trust-related and lower priority.

---

## 0. What the Screenshots Actually Show

- **"brewline failed to start" / `sqlite3_initialize` / `error code 126`** — this is a real crash, app is unusable on that machine. This is Issue A, §1.
- **UAC "Voulez-vous autoriser cette application provenant d'un éditeur inconnu..." with `Éditeur : Inconnu`** — this is Windows' code-signing trust prompt, unrelated to the crash. This is Issue B, §2.
- The fact that the crash screen renders as a proper styled Flutter UI (not a raw OS crash dialog) confirms the core Flutter engine and its DLLs loaded fine — the failure is isolated specifically to the SQLite native library. That's an important clue: it rules out a broader "missing Visual C++ Redistributable" theory, which would have prevented the engine itself from starting.

---

## 1. Issue A (priority): SQLite Native Library Fails to Load on Windows

### 1.1 Root cause
`sqflite_common_ffi` talks to SQLite via `dart:ffi`, which means it needs an actual `sqlite3` shared library sitting on disk to load — `sqlite3.dll` on Windows, `libsqlite3.so` on Linux. Unlike Android (which already ships a system SQLite that Android's plugins can use), **Windows has no guaranteed system-wide `sqlite3.dll`** — if the app doesn't bundle its own copy right next to the executable, there's nothing for it to load. Error `126` from `LoadLibrary` specifically means "the module could not be found" — consistent with the file simply not being present in the shipped folder, which matches what's visible in the Explorer screenshot: no `sqlite3.dll` next to `brewline.exe`.

The most likely explanation is one of these two, and it's worth checking both rather than guessing:
1. **The project has no dependency that bundles a native `sqlite3` binary for desktop.** `sqflite_common_ffi` itself doesn't ship the library — it only knows how to *talk* to one via FFI. Something else has to put the actual `.dll`/`.so` file into the build output.
2. **The release packaging step for OTA distribution (the zip built for Windows in `CASHOUT_PRINTING_SPEC.md`/`OTA_UPDATE_SYSTEM_SPEC.md`) didn't copy the full `Release/` build output.** Even if the DLL exists in the raw `flutter build windows` output, a packaging script that cherry-picks files instead of zipping the whole folder could easily have dropped it.

### 1.2 Fix
Add **`sqlite3_flutter_libs`** as a direct dependency in `pubspec.yaml`, on top of the existing `sqflite_common_ffi`. This package's entire job is bundling the correct precompiled native `sqlite3` binary for whichever platform is being built — Flutter's build tooling automatically copies it into the right place in `build/windows/.../Release/` and `build/linux/.../bundle/lib/` during a normal `flutter build`. Add it even though Android doesn't strictly need it (Android already has a usable system library) — it's harmless there and keeps the dependency story consistent across all three platforms rather than having Windows/Linux rely on something that isn't explicitly declared.

```yaml
dependencies:
  sqflite_common_ffi: ^2.x.x   # existing
  sqlite3_flutter_libs: ^0.5.x # add this
```

No changes needed to `database_helper.dart`'s use of `databaseFactoryFfi` — `sqlite3_flutter_libs` just makes sure the library `sqflite_common_ffi` is already looking for actually exists on disk; it doesn't change how the app talks to it.

### 1.3 Fix the packaging step too, regardless of which cause it turns out to be
Whatever script builds the Windows `.zip` and Linux `.tar.gz` for OTA distribution must archive the **entire** `Release`/`bundle` output directory recursively — every DLL/`.so`, the `data/` folder, everything `flutter build` produced — not a hand-picked subset of files. This is worth fixing even if adding `sqlite3_flutter_libs` alone resolves the crash, because a packaging step that can silently drop one required file can drop another one later.

### 1.4 Verification — don't just test on the dev machine
This bug likely didn't show up during development because a machine with the Flutter SDK and its tooling installed already has stray copies of common DLLs lying around, masking exactly this kind of missing-file bug. Test the *actual shipped zip* on a clean machine (or at minimum a different one than whatever built it) that has never had Flutter installed:
1. Run `flutter build windows --release` (and `flutter build linux --release`), confirm `sqlite3.dll` / `libsqlite3.so` now appears in the output folder alongside the exe.
2. Build the distribution archive exactly the way the real release process does (§1.3).
3. Unzip/untar it on a clean machine and launch the app from there — not from the build output folder directly, since that's not what an end user will ever run.
4. Repeat the same check for Linux specifically — the reasoning in §1.1 doesn't guarantee Linux was safe just because the visible crash was on Windows; some distros also lack a usable system `libsqlite3`, so confirm this didn't exist there too, silently, unreported.

---

## 2. Issue B (lower priority): "Unknown Publisher" & Missing Exe Metadata

These are two separate things, worth being precise about since they have different fixes and different costs:

### 2.1 Exe metadata (cheap, do this)
Windows Explorer's file Properties → Details tab (Company, Product Name, File Description, Version) pulls from a `VERSIONINFO` resource block that Flutter's default Windows template leaves mostly blank/generic. Edit `windows/runner/Runner.rc` and fill in:
- `CompanyName` → your name/café brand
- `ProductName` → "Brewline"
- `FileDescription` → "Brewline Café POS"
- `ProductVersion` / `FileVersion` → sourced from `pubspec.yaml`'s `version:` field, kept in sync at build time rather than hand-edited separately

This makes the app look properly identified in Explorer and Task Manager. **It will not change what the UAC prompt shows, though** — that's §2.2.

### 2.2 "Unknown Publisher" in the UAC prompt (bigger, optional — not required to ship)
This specific field comes from Windows checking for a valid Authenticode code-signing signature on the exe — it has nothing to do with the metadata in §2.1. Filling in `Runner.rc` perfectly will still show "Unknown Publisher" with no signature behind it. This was already flagged as an optional, not-required-to-ship item in the OTA plan (a paid code-signing cert removes it entirely; a self-signed cert can work for a handful of café-owned devices but has to be manually trusted on each one). Nothing new to decide here — just confirming this screenshot is that same known, already-documented trade-off, not a new problem.

### 2.3 Linux parity (small, optional)
Linux doesn't have a UAC-style prompt, but has a rough equivalent of "no metadata": if the app is missing a proper `.desktop` entry, it may show up unlabeled or generically in a file manager/app launcher. If one doesn't already exist, add a `brewline.desktop` file with `Name=Brewline`, a `Comment`, an `Icon`, and an appropriate `Categories` entry — cheap parity with the Windows metadata fix, not required for the app to function.

---

## 3. Documentation Requirements

- `pubspec.yaml`'s `sqlite3_flutter_libs` entry gets a one-line comment explaining it's there specifically to bundle the native library for Windows/Linux desktop builds — otherwise a future dependency cleanup might see it as unused (since nothing calls it directly in Dart code) and remove it, reintroducing this exact crash.
- The release packaging script (wherever it lives — the GitHub Actions workflow mentioned in the OTA spec, or a local script) gets a comment stating explicitly that it must archive the full build output directory, cross-referencing this bug as the reason.
- `Runner.rc`'s version fields get a comment noting they should be kept in sync with `pubspec.yaml`'s version — ideally automated in the release workflow rather than hand-edited per release.

---

## 4. Acceptance Checklist

- [ ] `sqlite3_flutter_libs` added to `pubspec.yaml`; `flutter build windows --release` output now includes `sqlite3.dll` next to the exe
- [ ] `flutter build linux --release` output includes `libsqlite3.so` in the bundle
- [ ] Android build unaffected — still launches and reads/writes the database correctly (confirms adding the package didn't regress the platform that already worked)
- [ ] The actual distributed `.zip`/`.tar.gz` (not just the raw build folder) contains the SQLite native library — verified by inspecting the archive contents directly, not assumed
- [ ] App launches successfully from that archive on a clean Windows machine with no Flutter SDK ever installed
- [ ] App launches successfully from that archive on a clean/different Linux machine
- [ ] `Runner.rc` shows correct Company/Product/Description/Version in Explorer's Properties → Details tab
- [ ] Confirmed (not assumed) that the UAC "Unknown Publisher" prompt is unaffected by the metadata fix alone — expected, not a regression
- [ ] (Optional) Linux `.desktop` file shows correct name/icon in the file manager/app launcher

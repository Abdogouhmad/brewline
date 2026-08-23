# brewline — task runner
# Install: https://github.com/casey/just  (or `cargo install just`)
# Run `just` or `just --list` to see all available commands with summaries.
# Run `just --show <recipe>` to see the raw commands a recipe executes.

# default recipe: show the list of commands
default:
    @just --list

# ── Dependencies ─────────────────────────────────────────────────────────────

# fetch project dependencies from pub.dev (run after cloning or changing pubspec.yaml)
deps:
    flutter pub get

# regenerate launcher icons from assets/icons/png/icon_1024.png (android + windows)
icons:
    dart run flutter_launcher_icons

# upgrade all dependencies to their newest allowed versions
upgrade:
    flutter pub upgrade

# ── Development ──────────────────────────────────────────────────────────────

# run the app on linux desktop (hot reload enabled)
run-linux:
    flutter run -d linux

# run the app on windows desktop (hot reload enabled; needs Windows + VS toolchain)
run-windows:
    flutter run -d windows

# run the app on an attached/emulated android device
run-android:
    flutter run -d android

# list all devices/emulators flutter can currently see
devices:
    flutter devices

# ── Quality checks ───────────────────────────────────────────────────────────

# static analysis: lints + type errors (fast; run this before every commit)
analyze:
    flutter analyze

# run all unit/widget tests
test:
    flutter test

# auto-format all dart files and apply analysis fixes
fmt:
    dart format .
    dart fix --apply

# full check: format + analyze + test (use before pushing)
check: fmt analyze test

# ── Builds (release) ─────────────────────────────────────────────────────────

# build a release binary for linux into build/linux/x64/release/bundle/
build-linux:
    flutter build linux

# build a release .exe for windows into build/windows/x64/runner/Release/
build-windows:
    flutter build windows

# build a release APK for android into build/app/outputs/flutter-apk/
build-android:
    flutter build apk

# build a fat release APK (works on arm32 + arm64 + x86_64, bigger file but universal)
build-android-universal:
    flutter build apk --target-platform android-arm,android-arm64,android-x64

# build everything the current OS can build (linux machine → linux + apk)
build-all: build-linux build-android

# ── Maintenance ──────────────────────────────────────────────────────────────

# delete all build artifacts and ephemeral files (safe; deps stay in cache)
clean:
    flutter clean

# nuke everything and start fresh: clean + refetch deps + regenerate icons
reset: clean deps icons

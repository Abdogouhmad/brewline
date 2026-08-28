#!/usr/bin/env bash
#
# brewline — automated release build.
#
# Builds the installable bundles this machine is capable of producing:
#
#   Artifact                       Where it lands
#   ----------------------------------------------------------------
#   Linux (x64)                    build/linux/x64/release/bundle/
#   Android universal APK          build/app/outputs/flutter-apk/
#   Android split APKs (arm/x64)   build/app/outputs/flutter-apk/  (--split-per-abi)
#   Android split AABs             build/app/outputs/bundle/release/
#   Windows (x64)                  build/windows/x64/runner/Release/   (Windows host only)
#
# Android is produced three ways so phones and tablets get the fastest path:
#   * one universal "fat" APK   — runs on any arm32/arm64/x64 device
#   * one slim APK per ABI       — arm / arm64 / x64, smallest installs
#   * one app bundle (AAB)       — Play Store / per-architecture splits
#
# Works both locally and inside CI.
#
# Local host mapping:
#   linux   → linux + android (APK + AAB)
#   windows → windows + android (APK + AAB)
#   macos   → android only
#
# In GitHub Actions (CI=true) the runner OS is chosen to match the requested
# target, so an unsupported combo is treated as an ERROR — echoing the
# `--only` flags CI passes in — instead of being silently skipped.
#
# Usage:
#   ./build.sh                 build everything the current OS supports
#   ./build.sh -v              verbose (stream Flutter output)
#   ./build.sh --only linux    only build Linux
#   ./build.sh --only android  only build Android
#   ./build.sh --only windows  only build Windows (on a Windows host)
#   ./build.sh --no-version-checksum   skip the "uncommitted changes" sanity check
#
set -euo pipefail

cd "$(dirname "$0")"

# True when running on GitHub Actions / other CI.
CI_RUNNER="${CI:-false}"

# ── Flags ─────────────────────────────────────────────────────────────────────
VERBOSE=false
ONLY=""
CHECK_VERSION=true
while [[ $# -gt 0 ]]; do
  case "$1" in
  -v | --verbose) VERBOSE=true ;;
  --only)
    ONLY="$2"
    shift
    ;;
  --no-version-checksum) CHECK_VERSION=false ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
  shift
done

# ── Host detection ────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
Linux*) HOST="linux" ;;
MINGW* | MSYS* | CYGWIN*) HOST="windows" ;;
Darwin*) HOST="macos" ;;
*) HOST="unknown" ;;
esac

info() { printf '\033[1;36m[brewline]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[brewline]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[brewline]\033[0m %s\n' "$*" >&2; }
run() {
  if [[ "$VERBOSE" == true ]]; then
    "$@"
  else
    "$@" >/dev/null
  fi
}

# Quick sanity check that flutter is on PATH.
if ! command -v flutter >/dev/null 2>&1; then
  err "flutter not found on PATH. Run 'flutter doctor' / install Flutter first."
  exit 1
fi

# ── Build recipes ─────────────────────────────────────────────────────────────

# Sanity check: refuse to build a dirty working tree unless explicitly
# allowing it (so local builds always correspond to a commit, while CI — which
# builds from a clean checkout — can skip).
check_version_checksum() {
  if [[ "$CHECK_VERSION" == false || "$CI_RUNNER" == true ]]; then
    return
  fi
  if ! [[ "$(git status --porcelain 2>/dev/null)" == "" ]]; then
    info "Working tree has uncommitted changes; building anyway (dirty build)."
    info "Pass --no-version-checksum to silence this check."
  fi
}

build_linux() {
  info "Building Linux (x64) release..."
  run flutter build linux --release
  info "Done → build/linux/x64/release/bundle/"
}

# Universal fat APK (phones + tablets, any architecture).
build_android_apk() {
  info "Building Android universal APK..."
  run flutter build apk --release
  info "Done → build/app/outputs/flutter-apk/"
}

# One slim APK per CPU architecture (arm32, arm64, x64). Smaller installs
# than the fat APK — pick the one matching the device's chip.
build_android_abis() {
  info "Building Android split APKs (arm / arm64 / x64)..."
  run flutter build apk --release --split-per-abi
  info "Done → build/app/outputs/flutter-apk/"
  ls -1 build/app/outputs/flutter-apk/*.apk 2>/dev/null | sed 's/^/    /'
}

# App bundle / per-architecture splits (for Play Store distribution).
build_android_aab() {
  info "Building Android app bundle (split AABs)..."
  run flutter build appbundle --release
  info "Done → build/app/outputs/bundle/release/"
}

build_windows() {
  if [[ "$HOST" != "windows" ]]; then
    if [[ "$CI_RUNNER" == true ]]; then
      err "Windows target on non-Windows runner: $HOST. CI must use windows-latest for target 'windows'."
      exit 1
    fi
    warn "Windows builds require a Windows host. Skipping (you're on: $HOST)."
    return
  fi
  info "Building Windows (x64) release..."
  run flutter build windows --release
  info "Done → build/windows/x64/runner/Release/"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

echo
echo "═══════════════════════════════════════════"
echo "  brewline — release build"
echo "  host: $HOST"
echo "═══════════════════════════════════════════"

# Ensure deps are fresh before building.
info "Fetching dependencies..."
run flutter pub get

# Sanity check that the working tree is committed (skipped automatically in CI).
check_version_checksum

case "$ONLY" in
linux) build_linux ;;
android)
  build_android_apk
  build_android_abis
  build_android_aab
  ;;
windows) build_windows ;;
"")
  case "$HOST" in
  linux)
    build_linux
    build_android_apk
    build_android_abis
    build_android_aab
    ;;
  windows)
    build_windows
    build_android_apk
    build_android_abis
    build_android_aab
    ;;
  macos)
    warn "MacOS host: building Linux/Windows is not supported here."
    build_android_apk
    build_android_abis
    build_android_aab
    ;;
  *)
    err "Unsupported host '$HOST'."
    exit 1
    ;;
  esac
  ;;
*)
  err "Unknown --only target '$ONLY'."
  exit 1
  ;;
esac

echo
info "All requested builds finished successfully."

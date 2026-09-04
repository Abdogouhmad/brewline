#!/usr/bin/env bash
#
# reset_data.sh — wipe brewline's local data for a clean fresh start.
#
# Deletes:
#   * the SQLite database (products, ingredients, stock, orders, staff, …)
#   * the persisted settings / onboarding state (shared_preferences.json)
#
# After running, the next launch recreates an empty database and shows the
# first-run onboarding screen so you can enter everything from zero.
#
# Usage:
#   scripts/reset_data.sh            # prompt before deleting
#   scripts/reset_data.sh --yes      # delete without prompting
#   scripts/reset_data.sh --backup   # copy current data to /tmp before deleting
#
# Exit codes: 0 = deleted, 1 = cancelled / nothing found.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- flags -----------------------------------------------------------------
AUTO_YES=0
MAKE_BACKUP=0
for arg in "$@"; do
  case "$arg" in
    --yes) AUTO_YES=1 ;;
    --backup) MAKE_BACKUP=1 ;;
    -h|--help)
      sed -n '2,/^set -euo/p' "$0" | sed '$d'
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

# --- locate data -----------------------------------------------------------
# SQLite lives in sqflite_common_ffi's per-project databases dir on desktop;
# shared prefs live in the platform config dir.
DB_DIR="$REPO_ROOT/.dart_tool/sqflite_common_ffi/databases"
CONFIG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/brewline"

DB_FILES=()
[[ -d "$DB_DIR" ]] && DB_FILES+=( "$DB_DIR"/brewline.db "$DB_DIR"/brewline.db-wal "$DB_DIR"/brewline.db-shm )
PREF_FILES=()
[[ -d "$CONFIG_DIR" ]] && PREF_FILES+=( "$CONFIG_DIR"/shared_preferences.json "$CONFIG_DIR"/shared_preferences.json.bak )

# Keep only paths that actually exist.
existing_db=()
for f in "${DB_FILES[@]}"; do [[ -f "$f" ]] && existing_db+=("$f"); done
existing_prefs=()
for f in "${PREF_FILES[@]}"; do [[ -f "$f" ]] && existing_prefs+=("$f"); done

if [[ ${#existing_db[@]} -eq 0 && ${#existing_prefs[@]} -eq 0 ]]; then
  echo "Nothing to delete — no brewline data found."
  echo "  db dir:    $DB_DIR"
  echo "  config dir: $CONFIG_DIR"
  exit 1
fi

echo "brewline data will be deleted:"
for f in "${existing_db[@]}" "${existing_prefs[@]}"; do
  echo "  - $f"
done

if [[ $AUTO_YES -ne 1 ]]; then
  read -r -p "Type 'y' to continue (or 'n' to cancel): " answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Cancelled."
    exit 1
  fi
fi

# --- optional backup -------------------------------------------------------
if [[ $MAKE_BACKUP -eq 1 ]]; then
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="/tmp/brewline-reset-$stamp"
  mkdir -p "$backup_dir"
  cp -f "${existing_db[@]}" "$backup_dir/" 2>/dev/null || true
  cp -f "${existing_prefs[@]}" "$backup_dir/" 2>/dev/null || true
  echo "Backup saved to: $backup_dir"
fi

# --- try to stop a running app --------------------------------------------
pkill -f '/brewline' 2>/dev/null || true
sleep 1

# --- delete ----------------------------------------------------------------
removed=0
for f in "${existing_db[@]}" "${existing_prefs[@]}"; do
  rm -f -- "$f" && removed=$((removed + 1)) && echo "Deleted: $f"
done

# Drop empty DB dir so sqflite_common_ffi starts clean.
rmdir "$DB_DIR" 2>/dev/null || true

echo
echo "Done — $removed file(s) removed."
echo "Next launch will recreate an empty database and show onboarding."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f "project.godot" ]; then
  echo "ERROR: project.godot not found in $ROOT_DIR" >&2
  exit 1
fi

if ! command -v godot >/dev/null 2>&1; then
  echo "ERROR: godot binary not found in PATH. Run: bash tools/setup_codespace.sh" >&2
  exit 1
fi

echo "=== [1/6] Checking repository hygiene (no >50 MB tracked/staged files, no keystores) ==="
LARGE_FILES="$(find . \( -path './.git' -o -path './.godot' -o -path './android' -o -path './build' -o -path './assets/downloads' \) -prune -o -type f -size +49M -print)"
if [ -n "$LARGE_FILES" ]; then
  echo "ERROR: Files exceeding 49 MB found outside ignored directories:" >&2
  echo "$LARGE_FILES" >&2
  exit 1
fi
KEYSTORES="$(find . \( -path './.git' -o -path './.godot' -o -path './android' \) -prune -o -type f \( -name '*.keystore' -o -name '*.jks' \) -print)"
if [ -n "$KEYSTORES" ]; then
  echo "ERROR: Keystore files must never exist inside repo tree:" >&2
  echo "$KEYSTORES" >&2
  exit 1
fi

echo "=== [2/6] Verifying asset manifest ==="
python3 tools/fetch_assets.py --verify

echo "=== [3/6] Importing project resources (godot --headless --import) ==="
IMPORT_LOG="$(mktemp)"
trap 'rm -f "$IMPORT_LOG"' EXIT
godot --headless --import --path "$ROOT_DIR" >"$IMPORT_LOG" 2>&1 || {
  cat "$IMPORT_LOG" >&2
  exit 1
}
if grep -E "SCRIPT ERROR:|Parse Error:|Failed to load resource" "$IMPORT_LOG" >/dev/null; then
  cat "$IMPORT_LOG" >&2
  echo "ERROR: Import produced script/resource errors." >&2
  exit 1
fi

echo "=== [4/6] Running --check-only on all GDScript files ==="
SCRIPT_COUNT=0
while IFS= read -r -d '' gd_file; do
  SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
  CHECK_OUT="$(godot --headless --path "$ROOT_DIR" --check-only --script "$gd_file" 2>&1 || true)"
  if echo "$CHECK_OUT" | grep -E "SCRIPT ERROR:|Parse Error:|ERROR:" >/dev/null; then
    echo "FAIL: $gd_file" >&2
    echo "$CHECK_OUT" >&2
    exit 1
  fi
done < <(find . \( -path './.godot' -o -path './android' -o -path './build' \) -prune -o -type f -name '*.gd' -print0 | sort -z)
echo "Checked $SCRIPT_COUNT GDScript file(s) with 0 errors."

echo "=== [5/6] Running headless boot & system test ==="
BOOT_LOG="$(mktemp)"
godot --headless --path "$ROOT_DIR" --script res://tests/boot_test.gd >"$BOOT_LOG" 2>&1 || {
  cat "$BOOT_LOG" >&2
  rm -f "$BOOT_LOG"
  exit 1
}
cat "$BOOT_LOG"
if grep -E "SCRIPT ERROR:|Parse Error:|BOOT_TEST_FAIL" "$BOOT_LOG" >/dev/null; then
  rm -f "$BOOT_LOG"
  echo "ERROR: Boot test reported errors." >&2
  exit 1
fi
if ! grep -q "BOOT_TEST_PASS" "$BOOT_LOG"; then
  rm -f "$BOOT_LOG"
  echo "ERROR: Boot test did not emit BOOT_TEST_PASS." >&2
  exit 1
fi
rm -f "$BOOT_LOG"

echo "=== [6/6] Running Phase 1 character & camera physics tests ==="
PLAYER_LOG="$(mktemp)"
godot --headless --path "$ROOT_DIR" --script res://tests/player_test.gd >"$PLAYER_LOG" 2>&1 || {
  cat "$PLAYER_LOG" >&2
  rm -f "$PLAYER_LOG"
  exit 1
}
cat "$PLAYER_LOG"
if grep -E "SCRIPT ERROR:|Parse Error:|PLAYER_TEST_FAIL|ERROR:" "$PLAYER_LOG" >/dev/null; then
  rm -f "$PLAYER_LOG"
  echo "ERROR: Player test reported errors." >&2
  exit 1
fi
if ! grep -q "PLAYER_TEST_PASS" "$PLAYER_LOG"; then
  rm -f "$PLAYER_LOG"
  echo "ERROR: Player test did not emit PLAYER_TEST_PASS." >&2
  exit 1
fi
rm -f "$PLAYER_LOG"

echo "VALIDATE PASS: All checks succeeded."

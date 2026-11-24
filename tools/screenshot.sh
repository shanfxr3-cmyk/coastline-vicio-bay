#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_DIR="$ROOT_DIR/tests/screenshots"
mkdir -p "$OUT_DIR"

ICD=""
for candidate in /usr/share/vulkan/icd.d/lvp_icd.json /usr/share/vulkan/icd.d/lvp_icd.x86_64.json; do
  if [ -f "$candidate" ]; then
    ICD="$candidate"
    break
  fi
done

if [ -z "$ICD" ]; then
  echo "ERROR: Mesa Lavapipe Vulkan ICD not found in /usr/share/vulkan/icd.d/" >&2
  exit 1
fi

RENDERER="${1:-mobile}"
OUT_FILE="${2:-$OUT_DIR/phase0_${RENDERER}.png}"
RES="${3:-1280x720}"
FRAMES="${4:-30}"

echo "Rendering scene with renderer=$RENDERER (${RES}, ${FRAMES} frames) -> $OUT_FILE"

export VK_ICD_FILENAMES="$ICD"
export XDG_RUNTIME_DIR="/tmp/xdg-runtime-$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

xvfb-run -a -s "-screen 0 1280x720x24" \
  godot --path "$ROOT_DIR" \
  --audio-driver Dummy \
  --display-driver x11 \
  --rendering-driver vulkan \
  --rendering-method "$RENDERER" \
  --windowed \
  --resolution "$RES" \
  -- "--screenshot=$OUT_FILE" "--screenshot-frames=$FRAMES"

if [ ! -f "$OUT_FILE" ] || [ ! -s "$OUT_FILE" ]; then
  echo "ERROR: Screenshot not generated at $OUT_FILE" >&2
  exit 1
fi

echo "Screenshot saved: $OUT_FILE ($(stat -c%s "$OUT_FILE") bytes)"

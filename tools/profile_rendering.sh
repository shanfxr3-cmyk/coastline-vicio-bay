#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

REPORT="${1:-/tmp/opencode/coastline-render-costs.json}"
FRAMES="${2:-30}"
RENDERER="${3:-mobile}"
ICD=""
for candidate in /usr/share/vulkan/icd.d/lvp_icd.json /usr/share/vulkan/icd.d/lvp_icd.x86_64.json; do
  if [ -f "$candidate" ]; then
    ICD="$candidate"
    break
  fi
done
if [ -z "$ICD" ]; then
  echo "ERROR: Mesa Lavapipe Vulkan ICD not found." >&2
  exit 1
fi

export VK_ICD_FILENAMES="$ICD"
export XDG_RUNTIME_DIR="/tmp/xdg-runtime-$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

echo "Profiling isolated LOW -> MEDIUM rendering costs (${FRAMES} frames/case)"
xvfb-run -a -s "-screen 0 1280x720x24" \
  godot --path "$ROOT_DIR" \
  --audio-driver Dummy \
  --display-driver x11 \
  --rendering-driver vulkan \
  --rendering-method "$RENDERER" \
  --windowed \
  --resolution 1280x720 \
  --script res://tests/render_cost_test.gd \
  -- "--cost-frames=$FRAMES" "--cost-report=$REPORT" "--quality=low"

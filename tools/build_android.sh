#!/usr/bin/env bash
set -euo pipefail

# Coastline: Vicio Bay — Deterministic Android APK / AAB Builder
# Usage: bash tools/build_android.sh <standard|ultra> <apk|aab> <output_path>

TIER="${1:-standard}"
FORMAT="${2:-apk}"
OUT_PATH="${3:-build/coastline-vicio-bay-${TIER}.${FORMAT}}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

GODOT_DIR_VER="${GODOT_DIR_VER:-4.7.2.stable}"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/$GODOT_DIR_VER"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

if [ "$TIER" != "standard" ] && [ "$TIER" != "ultra" ]; then
  echo "ERROR: Invalid tier '$TIER' (expected 'standard' or 'ultra')" >&2
  exit 1
fi
if [ "$FORMAT" != "apk" ] && [ "$FORMAT" != "aab" ]; then
  echo "ERROR: Invalid format '$FORMAT' (expected 'apk' or 'aab')" >&2
  exit 1
fi

BACKUP_DIR="$(mktemp -d)"
cp project.godot "$BACKUP_DIR/project.godot"
cp export_presets.cfg "$BACKUP_DIR/export_presets.cfg"
cleanup() {
  cp "$BACKUP_DIR/project.godot" project.godot
  cp "$BACKUP_DIR/export_presets.cfg" export_presets.cfg
  rm -rf "$BACKUP_DIR"
}
trap cleanup EXIT

# 1. Ensure Android build template is extracted cleanly
if [ ! -f "android/.build_version" ] || ! grep -q "$GODOT_DIR_VER" "android/.build_version" 2>/dev/null; then
  if [ ! -f "$TEMPLATES_DIR/android_source.zip" ]; then
    echo "ERROR: Missing $TEMPLATES_DIR/android_source.zip" >&2
    exit 1
  fi
  rm -rf android/build
  mkdir -p android/build
  unzip -oq "$TEMPLATES_DIR/android_source.zip" -d android/build
  printf '%s\n' "$GODOT_DIR_VER" > android/.build_version
fi

# 2. Tune Gradle JVM heap for 7-8 GB CI / Codespace containers
python3 - <<'PY'
from pathlib import Path

gp = Path("android/build/gradle.properties")
text = gp.read_text(encoding="utf-8")
lines = [l for l in text.splitlines() if not l.startswith(("org.gradle.jvmargs=", "org.gradle.daemon=", "android.suppressUnsupportedCompileSdk="))]
lines.extend([
    "org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m",
    "org.gradle.daemon=false",
    "android.suppressUnsupportedCompileSdk=36",
])
gp.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

# 3. Ensure debug keystore exists and configure Godot editor settings
if [ ! -f "$HOME/.android/debug.keystore" ]; then
  mkdir -p "$HOME/.android"
  keytool -genkeypair -v -keystore "$HOME/.android/debug.keystore" \
    -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"
fi

godot --headless --quit >/dev/null 2>&1 || true
python3 - <<'PY'
import os
from pathlib import Path

cfg = Path.home() / ".config/godot/editor_settings-4.7.tres"
cfg.parent.mkdir(parents=True, exist_ok=True)
text = cfg.read_text(encoding="utf-8") if cfg.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
updates = {
    "export/android/android_sdk_path": f'"{os.environ.get("ANDROID_HOME", str(Path.home() / "Android/Sdk"))}"',
    "export/android/java_sdk_path": f'"{os.environ.get("JAVA_HOME", "/usr/lib/jvm/java-17-openjdk-amd64")}"',
    "export/android/debug_keystore": f'"{Path.home() / ".android/debug.keystore"}"',
    "export/android/debug_keystore_user": '"androiddebugkey"',
    "export/android/debug_keystore_pass": '"android"',
}
lines = text.splitlines()
for k, v in updates.items():
    p = f"{k} ="
    found = False
    for i, l in enumerate(lines):
        if l.startswith(p):
            lines[i] = f"{k} = {v}"
            found = True
            break
    if not found:
        lines.append(f"{k} = {v}")
cfg.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

# 4. Patch project.godot renderer for STANDARD (mobile) vs ULTRA (forward_plus)
RENDERER="mobile"
FEATURE="Mobile"
if [ "$TIER" = "ultra" ]; then
  RENDERER="forward_plus"
  FEATURE="Forward Plus"
fi

BUILD_RENDERER="$RENDERER" BUILD_FEATURE="$FEATURE" python3 - <<'PY'
import os
from pathlib import Path

renderer = os.environ["BUILD_RENDERER"]
feature = os.environ["BUILD_FEATURE"]
pg = Path("project.godot")
text = pg.read_text(encoding="utf-8")
lines = text.splitlines()
out = []
for line in lines:
    if line.startswith("renderer/rendering_method="):
        out.append(f'renderer/rendering_method="{renderer}"')
    elif line.startswith("renderer/rendering_method.mobile="):
        out.append(f'renderer/rendering_method.mobile="{renderer}"')
    elif line.startswith("config/features="):
        out.append(f'config/features=PackedStringArray("4.7", "{feature}")')
    else:
        out.append(line)
pg.write_text("\n".join(out) + "\n", encoding="utf-8")
PY

# 5. Select preset & signing mode (release if keystore env vars provided, else debug)
PRESET="Android"
if [ "$FORMAT" = "aab" ]; then
  PRESET="Android_AAB"
fi

EXPORT_CMD="--export-debug"
if [ -n "${RELEASE_KEYSTORE_PATH:-}" ] && [ -f "${RELEASE_KEYSTORE_PATH:-}" ] && \
   [ -n "${RELEASE_KEYSTORE_ALIAS:-}" ] && [ -n "${RELEASE_KEYSTORE_PASSWORD:-}" ]; then
  echo "Using release signing keystore for $PRESET..."
  python3 - <<PY
import os
from pathlib import Path

ep = Path("export_presets.cfg")
text = ep.read_text(encoding="utf-8")
ks_path = os.environ["RELEASE_KEYSTORE_PATH"]
ks_user = os.environ["RELEASE_KEYSTORE_ALIAS"]
ks_pass = os.environ["RELEASE_KEYSTORE_PASSWORD"]
extra = f'\nkeystore/release="{ks_path}"\nkeystore/release_user="{ks_user}"\nkeystore/release_password="{ks_pass}"\n'
text = text.replace('permissions/vibrate=true', 'permissions/vibrate=true' + extra)
ep.write_text(text, encoding="utf-8")
PY
  EXPORT_CMD="--export-release"
else
  echo "Notice: Release keystore secrets not configured; exporting debug-signed $FORMAT for $TIER ($PRESET)."
fi

mkdir -p "$(dirname "$OUT_PATH")"
godot --headless --path "$ROOT_DIR" --import >/dev/null 2>&1 || true
godot --headless --path "$ROOT_DIR" "$EXPORT_CMD" "$PRESET" "$OUT_PATH"

if [ ! -f "$OUT_PATH" ] || [ ! -s "$OUT_PATH" ]; then
  echo "ERROR: Export failed — missing $OUT_PATH" >&2
  exit 1
fi

echo "SUCCESS: Built $OUT_PATH ($(stat -c%s "$OUT_PATH") bytes)"

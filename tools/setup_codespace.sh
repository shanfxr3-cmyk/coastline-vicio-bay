#!/usr/bin/env bash
set -euo pipefail

# Coastline: Vicio Bay — Reproducible Codespace / Linux Toolchain Setup
# Installs Godot 4.7.2-stable, Export Templates, JDK 17, Android SDK/NDK,
# Blender headless, FFmpeg, SoX, ImageMagick, Python libs, Lavapipe, and Xvfb.

GODOT_VER="${GODOT_VER:-4.7.2-stable}"
GODOT_DIR_VER="${GODOT_DIR_VER:-4.7.2.stable}"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
JAVA_HOME_17="/usr/lib/jvm/java-17-openjdk-amd64"
TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/$GODOT_DIR_VER"

echo "[1/6] Installing system packages..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  openjdk-17-jdk blender ffmpeg sox libsox-fmt-all imagemagick \
  mesa-vulkan-drivers vulkan-tools xvfb \
  libfontconfig1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libgl1 libasound2t64 \
  unzip wget curl ca-certificates

echo "[2/6] Installing Python tooling libraries (numpy, Pillow, trimesh)..."
python3 -m pip install --quiet --upgrade numpy Pillow trimesh

echo "[3/6] Installing Godot $GODOT_VER..."
if ! command -v godot >/dev/null 2>&1 || ! godot --version 2>/dev/null | grep -q "^${GODOT_DIR_VER}"; then
  TMP_DIR="$(mktemp -d)"
  sudo mkdir -p /opt/godot
  wget -q -O "$TMP_DIR/godot.zip" "https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_linux.x86_64.zip"
  unzip -oq "$TMP_DIR/godot.zip" -d "$TMP_DIR"
  sudo mv "$TMP_DIR/Godot_v${GODOT_VER}_linux.x86_64" /opt/godot/godot
  sudo chmod +x /opt/godot/godot
  sudo ln -sf /opt/godot/godot /usr/local/bin/godot
  rm -rf "$TMP_DIR"
fi

echo "[4/6] Installing Godot $GODOT_VER export templates..."
if [ ! -f "$TEMPLATES_DIR/android_source.zip" ]; then
  TMP_DIR="$(mktemp -d)"
  mkdir -p "$TEMPLATES_DIR"
  wget -q -O "$TMP_DIR/templates.tpz" "https://github.com/godotengine/godot/releases/download/${GODOT_VER}/Godot_v${GODOT_VER}_export_templates.tpz"
  unzip -oq "$TMP_DIR/templates.tpz" -d "$TMP_DIR/unpack"
  mv "$TMP_DIR/unpack/templates/"* "$TEMPLATES_DIR/"
  rm -rf "$TMP_DIR"
fi

echo "[5/6] Installing Android SDK (API 36, Build-Tools 36.1.0, NDK 29.0.14206865)..."
export JAVA_HOME="$JAVA_HOME_17"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME
export ANDROID_SDK_ROOT="$ANDROID_HOME"

if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  TMP_DIR="$(mktemp -d)"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  wget -q -O "$TMP_DIR/cmdline-tools.zip" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
  unzip -oq "$TMP_DIR/cmdline-tools.zip" -d "$TMP_DIR/unpack"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$TMP_DIR/unpack/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf "$TMP_DIR"
fi

export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.1.0" "ndk;29.0.14206865"

if [ ! -f "$HOME/.android/debug.keystore" ]; then
  mkdir -p "$HOME/.android"
  keytool -genkeypair -v -keystore "$HOME/.android/debug.keystore" \
    -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"
fi

echo "[6/6] Configuring Godot editor settings for headless Android export..."
godot --headless --quit >/dev/null 2>&1 || true
python3 - <<'PY'
import os
from pathlib import Path

cfg = Path.home() / ".config/godot/editor_settings-4.7.tres"
cfg.parent.mkdir(parents=True, exist_ok=True)
text = cfg.read_text(encoding="utf-8") if cfg.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'

updates = {
    "export/android/android_sdk_path": f'"{os.environ.get("ANDROID_HOME", str(Path.home() / "Android/Sdk"))}"',
    "export/android/java_sdk_path": '"/usr/lib/jvm/java-17-openjdk-amd64"',
    "export/android/debug_keystore": f'"{Path.home() / ".android/debug.keystore"}"',
    "export/android/debug_keystore_user": '"androiddebugkey"',
    "export/android/debug_keystore_pass": '"android"',
}

lines = text.splitlines()
for key, val in updates.items():
    prefix = f"{key} ="
    replaced = False
    for i, line in enumerate(lines):
        if line.startswith(prefix):
            lines[i] = f"{key} = {val}"
            replaced = True
            break
    if not replaced:
        lines.append(f"{key} = {val}")

cfg.write_text("\n".join(lines) + "\n", encoding="utf-8")
print("Updated:", cfg)
PY

echo "Toolchain ready: $(godot --version)"

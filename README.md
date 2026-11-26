# Coastline: Vicio Bay

Original Godot 4 open-world crime game for Android arm64/Vulkan. Phase 0 and Phase 1 functionality are approved on a physical phone. Phase 2 is in progress with a major low-end optimisation pass and an original procedural sky foundation; the phone's 7–10 FPS regression remains under active verification (`docs/BUGS.md`, `B-006`).

## Reproduce the toolchain

```bash
bash tools/setup_codespace.sh
bash tools/validate.sh
bash tools/screenshot.sh mobile tests/screenshots/phase2_low.png 1280x720 30 low
bash tools/screenshot.sh mobile tests/screenshots/phase2_high.png 1280x720 30 high
bash tools/screenshot.sh forward_plus tests/screenshots/phase2_ultra.png 1280x720 30 high
```

The project uses Godot 4.7.2, JDK 17, Android SDK 36, and built-in Jolt physics. Seven-stage validation checks repository hygiene, the asset manifest, all 16 GDScript files, a headless boot of all seven autoloads and the main scene, eight character/camera physics regressions, and the Phase 2 preset/batching/collider performance suite. Screenshot quality arguments are optional; omitting one uses automatic detection.

## Build Android artifacts

```bash
bash tools/build_android.sh standard apk build/coastline-vicio-bay-standard.apk
bash tools/build_android.sh ultra apk build/coastline-vicio-bay-ultra.apk
bash tools/build_android.sh standard aab build/coastline-vicio-bay.aab
```

- **STANDARD** uses the Mobile renderer and is the first APK to test.
- **ULTRA** uses Forward+ and is intended for flagship Vulkan devices.
- Builds are arm64-only, with min SDK 24 and target SDK 36.
- Without release credentials, artifacts are explicitly debug-signed for testing and are not Play Store releases.

For a locally signed release AAB, provide `RELEASE_KEYSTORE_PATH`, `RELEASE_KEYSTORE_ALIAS`, and `RELEASE_KEYSTORE_PASSWORD`, then run the AAB command. The script restores all temporary project/export-setting changes on exit.

## Controls

| Action | Touch | Keyboard | Gamepad |
|---|---|---|---|
| Move | Left thumbstick | WASD / arrows | Left stick |
| Orbit camera | Drag right side | Mouse | Right stick |
| Sprint | **SPRINT** lock | Shift | Press left stick |
| Crouch / stand | **CROUCH** | C | B |
| Jump / vault | **JUMP** / **VAULT** | Space | A |
| Switch protagonist | **KIAN / SERA** | Tab | Y |

## Install and test on a phone

1. Open the latest successful **Build & Validate** run in GitHub Actions and download `coastline-standard-apk`.
2. Extract the ZIP, transfer the APK to the phone, and allow installation from the browser/file manager when Android prompts.
3. Launch **Coastline: Vicio Bay** and verify the lit Bayfront scene and articulated protagonist.
4. Test the left stick, right-side camera drag, **SPRINT**, **CROUCH**, and **JUMP**. Walk toward the low practice barrier and tap **VAULT** when it appears.
5. Tap **KIAN / SERA** to switch protagonists. Walk toward a wall while orbiting to confirm the camera pulls in without clipping.
6. Tap **TOD**, **QUAL**, and **DBG** to verify lighting presets, quality switching, and telemetry. Compare LOW, MEDIUM, and HIGH for at least 30 seconds each; the adaptive scale begins after warm-up. Record the on-screen FPS, draw calls, actual 3D resolution, and GPU name.
7. Start with LOW on the 6 GB test phone. On a flagship Vulkan phone, also repeat the launch/control check with `coastline-ultra-apk`.

Report launch failures, black screens, touch problems, clipping, visual regressions, and per-preset FPS for version `0.3.0-p2`. Phase 1 functionality is approved, but performance sign-off remains open as `B-006`. Lavapipe screenshots are relative regression checks, not phone benchmarks.

## Configure CI release signing

In **GitHub → repository Settings → Secrets and variables → Actions**, add these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64 text of the release keystore, with no line breaks.
- `ANDROID_KEYSTORE_ALIAS`: the key alias.
- `ANDROID_KEYSTORE_PASSWORD`: the keystore/key password.

Then manually rerun **Build & Validate** on `dev`. CI automatically switches from debug to release signing when all three values exist. Never commit a keystore, password, or Base64 key material; preserve a secure backup of the upload key.

# Coastline: Vicio Bay

Original Godot 4 open-world crime game for Android arm64/Vulkan. Phase 0 and Phase 1 are phone-approved. The entry-level reference phone sustains LOW at 30 FPS (`B-006` resolved). Phase 2 now includes GPU/RAM device classification, automatic preset fallback, and a continuous 24-hour atmosphere; weather and richer clouds remain in progress.

## Reproduce the toolchain

```bash
bash tools/setup_codespace.sh
bash tools/validate.sh
bash tools/screenshot.sh mobile tests/screenshots/phase2_low.png 1280x720 30 low 16.75
bash tools/screenshot.sh mobile tests/screenshots/phase2_high.png 1280x720 30 high 16.75
bash tools/screenshot.sh mobile tests/screenshots/phase2_high_night.png 1280x720 30 high 0.0
bash tools/screenshot.sh forward_plus tests/screenshots/phase2_ultra.png 1280x720 30 high 16.75
bash tools/profile_rendering.sh /tmp/opencode/coastline-render-costs.json 30 mobile
```

The project uses Godot 4.7.2, JDK 17, Android SDK 36, and built-in Jolt physics. Eight-stage validation checks repository hygiene, the asset manifest, all 19 GDScript files, a headless boot of all seven autoloads and the main scene, eight character/camera physics regressions, GPU/RAM presets/fallback/uncap checks, and the continuous-atmosphere suite. Screenshot quality/time arguments are optional; omitting them uses automatic detection and the continuous clock.

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

## Device-class presets

| Preset | Intended device class | Target | Automatic behavior |
|---|---|---:|---|
| **LOW · ENTRY** | Entry-level, including the 6 GB reference phone | 30 FPS | Default on unknown GPUs and devices below 7 usable GiB |
| **MED · MID-RANGE** | Mid-range | 30 FPS | Falls to LOW after a ten-second average below 20 FPS |
| **HIGH · UPPER-MID** | Upper-mid | 60 FPS | Falls to MEDIUM after a ten-second average below 20 FPS |

Auto-detection uses GPU family/model and usable physical RAM, never CPU cores. Fallback saves the sustainable preset and shows a short HUD notice. Do not tune MEDIUM/HIGH from the entry-level phone.

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
| Jump TOD phase | **TOD** | — | — |
| Toggle telemetry | **DBG** | F3 | — |
| Uncap/restore FPS + V-Sync | DBG panel **FPS CAP** button | F4 | — |

## Install and test on a phone

1. Open the latest successful **Build & Validate** run in GitHub Actions and download `coastline-standard-apk`.
2. Extract the ZIP, transfer the APK to the phone, and allow installation from the browser/file manager when Android prompts.
3. Launch **Coastline: Vicio Bay** and verify the lit Bayfront scene and articulated protagonist.
4. Test the left stick, right-side camera drag, **SPRINT**, **CROUCH**, and **JUMP**. Walk toward the low practice barrier and tap **VAULT** when it appears.
5. Tap **KIAN / SERA** to switch protagonists. Walk toward a wall while orbiting to confirm the camera pulls in without clipping.
6. Tap **TOD** to jump between dawn/day/golden/blue/night while the 24-hour clock continues. Tap **QUAL** to verify class labels and fallback notices, and **DBG** for telemetry.
7. Start with LOW on the 6 GB entry phone and confirm it remains at 30 FPS. In the DBG panel, tap **FPS CAP** to measure uncapped LOW headroom; tap again to restore the 30 FPS cap and previous V-Sync mode.
8. MEDIUM/HIGH are not tuning targets on the entry phone. If their ten-second average remains below 20 FPS, confirm the one-preset fallback message. On a flagship Vulkan phone, also test `coastline-ultra-apk`.

Report launch failures, black screens, touch problems, clipping, visual regressions, and per-preset FPS for version `0.4.0-p2`. The original `B-006` LOW regression is resolved; any new LOW cycle regression needs fresh device evidence. Lavapipe screenshots/profiles are relative checks, not phone benchmarks.

## Configure CI release signing

In **GitHub → repository Settings → Secrets and variables → Actions**, add these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64 text of the release keystore, with no line breaks.
- `ANDROID_KEYSTORE_ALIAS`: the key alias.
- `ANDROID_KEYSTORE_PASSWORD`: the keystore/key password.

Then manually rerun **Build & Validate** on `dev`. CI automatically switches from debug to release signing when all three values exist. Never commit a keystore, password, or Base64 key material; preserve a secure backup of the upload key.

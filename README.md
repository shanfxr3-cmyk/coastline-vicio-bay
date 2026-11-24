# Coastline: Vicio Bay

Original Godot 4 open-world crime game for Android arm64/Vulkan. Phase 0 CI is green; physical-phone QA and CI release-signing secrets are still pending.

## Reproduce the toolchain

```bash
bash tools/setup_codespace.sh
bash tools/validate.sh
bash tools/screenshot.sh mobile tests/screenshots/phase0_standard.png 1280x720 10
```

The project uses Godot 4.7.2, JDK 17, Android SDK 36, and built-in Jolt physics. Validation checks repository hygiene, the asset manifest, every GDScript file, and a headless boot of all seven autoloads and the main scene.

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

## Install and test on a phone

1. Open the latest successful **Build & Validate** run in GitHub Actions and download `coastline-standard-apk`.
2. Extract the ZIP, transfer the APK to the phone, and allow installation from the browser/file manager when Android prompts.
3. Launch **Coastline: Vicio Bay** and verify the lit Bayfront scene.
4. Drag the left stick to move, swipe the right side to orbit, and tap **JUMP**.
5. Tap **TOD**, **QUAL**, and **DBG** to verify lighting presets, quality switching, and telemetry.

Report any launch failure, black screen, touch problem, or renderer-specific issue before Phase 0 sign-off. Performance and thermal claims require a physical device; Lavapipe screenshots are not a phone benchmark.

## Configure CI release signing

In **GitHub → repository Settings → Secrets and variables → Actions**, add these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64 text of the release keystore, with no line breaks.
- `ANDROID_KEYSTORE_ALIAS`: the key alias.
- `ANDROID_KEYSTORE_PASSWORD`: the keystore/key password.

Then manually rerun **Build & Validate** on `dev`. CI automatically switches from debug to release signing when all three values exist. Never commit a keystore, password, or Base64 key material; preserve a secure backup of the upload key.

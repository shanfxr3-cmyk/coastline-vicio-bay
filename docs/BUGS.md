# BUGS — Coastline: Vicio Bay

Track all discovered bugs here with severity (`P0` blocker, `P1` major, `P2` minor), repro steps, and resolution.

## Open Bugs

### `B-003` — P2 — Texture RIDs reported at screenshot shutdown
- **Repro:** Run `bash tools/screenshot.sh mobile tests/screenshots/phase0_standard.png 1280x720 10` with Lavapipe.
- **Observed:** The 1280×720 PNG saves successfully and the process exits zero, then Godot reports `WARNING: 7 RIDs of type "Texture" were leaked.` Also present in CI run `45389714024`.
- **Impact:** No observed capture or boot-test failure; resource-teardown hygiene still needs investigation. Reproduce on a physical device before treating it as engine-specific.
- **Next:** Inspect sky/reflection-probe/viewport teardown in P1 and make screenshot QA fail on new leak warnings.

## Resolved Bugs

### `B-001` — P0 — Sequential Android exports contaminated the next build
- **Repro:** Build STANDARD APK and then ULTRA APK in the same checkout (CI run `45354079765`).
- **Observed:** Godot imported `android/build`, produced duplicate UIDs and `.webp.import` files, tried to package the previous build, and failed ULTRA at `mergeStandardDebugResources`.
- **Fix:** `tools/build_android.sh` creates `android/.gdignore` before every Godot invocation (`f30d84a`).
- **Verified:** Local STANDARD APK → ULTRA APK → AAB sequence passed; CI run `45389714024` built and uploaded all three artifacts.

### `B-002` — P1 — Codespace inherited an incomplete Android SDK path
- **Observed:** The environment supplied `ANDROID_HOME=/Android/Sdk`, while the installed SDK was under `$HOME/Android/Sdk`; exports reported missing platform/build tools.
- **Fix:** The builder falls back to `$HOME/Android/Sdk` only when the inherited path lacks `platform-tools` and the local SDK is complete.
- **Verified:** All local APK/AAB exports and APK signature/AAB archive checks pass without manual environment overrides (`f30d84a`).

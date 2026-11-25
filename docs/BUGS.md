# BUGS — Coastline: Vicio Bay

Track all discovered bugs here with severity (`P0` blocker, `P1` major, `P2` minor), repro steps, and resolution.

## Open Bugs

### `B-003` — P2 — ReflectionProbe textures reported at screenshot shutdown
- **Repro:** Run `bash tools/screenshot.sh mobile tests/screenshots/phase1_standard.png 1280x720 20` with Lavapipe.
- **Observed:** The PNG saves successfully and exits zero, then Godot reports `WARNING: 7 RIDs of type "Texture" were leaked.` STANDARD and ULTRA behave identically.
- **Isolation:** An empty rendered scene exits cleanly. Removing `BayfrontProbe` before its first render also exits cleanly; enabling either `UPDATE_ONCE` or `UPDATE_ALWAYS` reproduces exactly seven leaked texture RIDs. Explicit scene destruction plus eight drain frames does not remove the warning.
- **Impact:** No observed boot, capture, gameplay, or user-phone failure. This appears scoped to Godot 4.7.2 ReflectionProbe GPU teardown under Lavapipe; required runtime reflections remain enabled.
- **Next:** Check physical-device logs during Phase 1 QA and reassess after a Godot patch upgrade. Do not “fix” it by silently removing reflections.

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

### `B-004` — P1 — Version changes missed the Gradle cache and hit Maven rate limits
- **Repro:** CI run `45539603043` changed `project.godot`/`export_presets.cfg`, missed the exact Gradle cache key, then received HTTP 429 from Maven Central while resolving Android dependencies.
- **Impact:** Validation and both screenshots passed, but the STANDARD build stopped before ULTRA/AAB; this was not a source, signing, or export failure.
- **Fix:** `83744f3` adds a Godot-version Gradle `restore-keys` fallback while retaining exact project/export keys for new cache entries.
- **Verified:** Runs `45542953786` and `45548311788` restored the previous Gradle cache and completed all three release-signed builds without HTTP 429.

### `B-005` — P1 — Local tooling and test scripts were included in Android exports
- **Observed:** Release-artifact inspection found `assets/opencode.json` and compiled boot/player test scripts in the AAB because Godot's `all_resources` export includes JSON/GDScript resources.
- **Fix:** `815445e` excludes `opencode.json`, `tests/*`, `tools/*`, and `docs/*` in both Android presets; runtime `assets/manifest.json` remains included.
- **Verified:** A local AAB content assertion passed, and every APK/AAB downloaded from run `45548311788` has valid CRCs with no `opencode.json` or test-script entries.

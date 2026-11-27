# BUGS — Coastline: Vicio Bay

Track all discovered bugs here with severity (`P0` blocker, `P1` major, `P2` minor), repro steps, and resolution.

## Open Bugs

### `B-003` — P2 — ReflectionProbe textures reported at screenshot shutdown
- **Repro:** Run `bash tools/screenshot.sh mobile tests/screenshots/phase1_standard.png 1280x720 20` with Lavapipe.
- **Observed:** The PNG saves successfully and exits zero, then Godot reports `WARNING: 7 RIDs of type "Texture" were leaked.` STANDARD and ULTRA behave identically.
- **Isolation:** An empty rendered scene exits cleanly. Removing `BayfrontProbe` before its first render also exits cleanly; enabling either `UPDATE_ONCE` or `UPDATE_ALWAYS` reproduces exactly seven leaked texture RIDs. Explicit scene destruction plus eight drain frames does not remove the warning.
- **Impact:** No observed boot, capture, gameplay, or user-phone failure. This appears scoped to Godot 4.7.2 ReflectionProbe GPU teardown under Lavapipe. LOW now honestly disables the runtime probe as part of its documented lower tier; MEDIUM/HIGH retain real reflections.
- **Next:** Check physical-device logs during the `0.3.0-p2` retest and reassess after a Godot patch upgrade. Do not silently remove reflections from tiers that advertise them.

## Resolved Bugs

### `B-006` — P0 — Phase 1 runs at 7–10 FPS on the accepted test phone
- **Device class:** POCO M6 Pro 5G/6 GB is the project's entry-level physical test device.
- **Original report:** Version `0.2.0-p1` measured approximately 7–10 FPS on LOW, MEDIUM, and HIGH despite functional Phase 1 approval.
- **Fix:** `27e5e08` applied real preset/shadow settings, conservative defaults, spatial MultiMesh batching, lower pixel/geometry cost, tiered lighting/effects, adaptive resolution, and expanded telemetry/tests.
- **Physical verification:** Version `0.3.0-p2` measured **LOW 30 FPS**, MEDIUM 15 FPS, HIGH 10 FPS on the same phone. LOW now meets its entry-level 30 FPS target; the original all-preset regression is resolved.
- **Device-class rule:** Do not tune MEDIUM/HIGH on this entry device. MEDIUM targets 30 FPS on mid-range hardware and HIGH targets 60 FPS on upper-mid hardware. GPU/RAM detection and automatic HIGH→MEDIUM→LOW fallback protect unsupported devices in `0.4.0-p2`.
- **Follow-up:** Recheck LOW 30 FPS after the continuous atmosphere update and verify fallback/uncapped controls on the entry phone. Any new LOW regression gets a new bug rather than reopening the resolved Phase 1 report.

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

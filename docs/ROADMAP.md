# ROADMAP — Coastline: Vicio Bay

> **Session Resume Protocol**: Read `docs/STUDIO_BIBLE.md`, `docs/ROADMAP.md`, `docs/BUGS.md`, and `docs/LIMITS.md` first, then continue from the first `[ ]` / `IN PROGRESS` item below.

## Phase Status Overview

| Phase | Name | Status | Target |
|---|---|---|---|
| **P0** | Build Pipeline, Skeleton, Touch Demo, CI (STANDARD / ULTRA / AAB) | `COMPLETE` | Phone accepted + release-signed CI verified |
| **P1** | Character Controller, Camera, Touch Controls | `COMPLETE — DEVICE PERFORMANCE FOLLOW-UP` | User-approved on 2026-11-25; 7–10 FPS regression tracked as `B-006` |
| **P2** | Sky, Clouds, Weather, Time of Day, Lighting | `IN PROGRESS` | Optimisation + procedural sky foundation done; cycle, clouds, weather remain |
| **P3** | District 1 (Bayfront / Palm Row), Road System, Chunk Streaming | `PENDING` | 128m threaded streaming chunks + roads |
| **P4** | Supercars, Traffic, Driving Feel | `PENDING` | Raycast RigidBody3D physics + hero cars |
| **P5** | Weapons, Combat, Ragdoll, Destruction | `PENDING` | Ballistics, PhysicalBoneSimulator3D, breakables |
| **P6** | Pedestrians, Police, Wanted System | `PENDING` | 1–5 star wanted AI, traffic/ped crowds |
| **P7** | Water, Boats, Aircraft | `PENDING` | Gerstner ocean, buoyancy, flight model |
| **P8** | Full Map Expansion (All Districts) | `PENDING` | 10+ km² Vicio Bay + islands |
| **P9** | Interiors and Activities | `PENDING` | Enterable safehouses/shops + minigames |
| **P10** | Cutscene Director, Story Chapters 1–3 | `PENDING` | JSON timeline director + Act I |
| **P11** | Story Chapters 4–8 | `PENDING` | Full 40+ mission campaign + 3 endings |
| **P12** | Economy, Heists, Hacking, Phone | `PENDING` | Smartphone OS, heist planning, crypto |
| **P13** | Audio, Music, Radio, Voice, Lip-Sync | `PENDING` | 8+ radio stations, Piper TTS, Rhubarb |
| **P14** | UI, Menus, Save/Load, Settings, Accessibility | `PENDING` | Full HUD, map/GPS, slots, remapping |
| **P15** | Realism Pass | `PENDING` | Strand hair, skin, cloth, paint, damage |
| **P16** | Optimisation | `PENDING` | Device presets, thermals, memory, battery |
| **P17** | QA Marathon | `PENDING` | Bug bash, balance, save-corruption tests |
| **P18** | Release Prep | `PENDING` | Signed AAB, pack splitting, store listing |

---

## Completed Phase: P0 — Build Pipeline, Skeleton, Touch Demo, CI

### Checklist
- [x] `P0.1` Repo governance (`AGENTS.md`, `opencode.json`, `.gitignore`, `docs/ART_BIBLE.md`, `docs/ROADMAP.md`, `docs/BUGS.md`, `docs/DEBT.md`, `docs/LIMITS.md`, `docs/CHANGELOG.md`, `CREDITS.md`)
- [x] `P0.2` Codespace & reproducible toolchain (`tools/setup_codespace.sh`, `.devcontainer/devcontainer.json`): Godot 4.7.2, export templates, JDK 17, Android SDK 36/NDK 29, Blender, FFmpeg, SoX, ImageMagick, Python libraries, Lavapipe, and Xvfb
- [x] `P0.3` Validation & rendering tools (`tools/validate.sh`, `tools/screenshot.sh`, `tools/fetch_assets.py`, `assets/manifest.json`)
- [x] `P0.4` Godot 4 project skeleton (`project.godot`, `export_presets.cfg`, Jolt physics, ETC2/ASTC, `com.coastline.viciobay`, and all required department folders)
- [x] `P0.5` Autoloads (`GameState`, `EventBus`, `SaveSystem`, `Settings`, `AudioBus`, `Streaming`, `Debug`)
- [x] `P0.6` Debug overlay (FPS, frame ms, draw calls, triangles, VRAM, RAM, streaming & physics stats)
- [x] `P0.7` Lit 3D coastal prototype scene + implemented touch controls (virtual joystick + swipe look + camera orbit + jump/TOD/quality/debug buttons); physical multi-touch verification is `P0.12`
- [x] `P0.8` Local `tools/validate.sh` pass + visual inspection of local STANDARD/ULTRA screenshots + local Android APK builds
- [x] `P0.9` `.github/workflows/build.yml` (STANDARD APK, ULTRA APK, AAB, release-signing support, cached Godot/templates/Gradle/imported resources) + keystore setup instructions in `README.md`; local release-signed AAB verified
- [x] `P0.10` Push to `dev`, `gh run watch` green CI for STANDARD, ULTRA, and AAB, update docs, commit & verification report
- [x] `P0.11` CI run `45548311788` logged release signing for STANDARD, ULTRA, and AAB; downloaded artifacts passed release-signature, package, archive, bundletool, and universal-APK conversion checks
- [x] `P0.12` User installed the STANDARD APK on a physical Android phone, reported that it “runs very good,” and explicitly approved starting Phase 1 on 2026-11-25; expanded Phase 1 controls will receive a fresh device check

### Initial Verification Report — 2026-11-24
- **Local validation:** `bash tools/validate.sh` passed: 10 scripts, seven autoloads, Jolt Physics, 25 chunks, seven audio buses.
- **Local repeatable build:** STANDARD APK (`80256019` bytes), ULTRA APK (`80256047` bytes), and debug AAB (`28349954` bytes) built sequentially without contamination. Both APK signatures and the AAB archive were verified.
- **Local release path:** `build/coastline-vicio-bay-release.aab` (`26599604` bytes) built using a keystore outside the repository; `jarsigner -verify` reported `jar verified` (expected self-signed/timestamp warnings).
- **Green CI:** [run `45389714024`](https://github.com/shanfxr3-cmyk/coastline-vicio-bay/actions/runs/45389714024), commit `f30d84a`, both jobs successful. Downloaded artifacts were signature/archive checked: STANDARD APK `80255783` bytes, ULTRA APK `80255811` bytes, AAB `28349725` bytes.
- **Historical signing status:** Run `45389714024` explicitly used debug signing; it was superseded by the release-signed verification below.
- **Screenshot:** Latest initial CI PNG was a valid 1280×720 image and earlier local renders passed visual inspection. Nonfatal shutdown warning is tracked as `B-003`.
- **Historical device status:** No physical phone was attached in CI; the user subsequently accepted Phase 0 on Android on 2026-11-25.

### Release Verification — 2026-11-25
- **Green release CI:** [run `45548311788`](https://github.com/shanfxr3-cmyk/coastline-vicio-bay/actions/runs/45548311788), commit `815445e`, both jobs successful. All three build steps explicitly used the release keystore.
- **APKs:** STANDARD (`74648792` bytes) and ULTRA (`74648808` bytes) pass APK Signature Scheme v2 verification with the same `CN=Coastline Release, O=Coastline, C=US` RSA-4096 certificate. Both are `com.coastline.viciobay` version `0.2.0-p1`, target SDK 36, arm64-only.
- **AAB:** Release AAB (`26618900` bytes) passes `jarsigner -verify`, ZIP CRC validation, bundletool `1.18.3 validate`, and universal-APK generation/archive checks. Expected self-signed/timestamp and JDK `JarInputStream` ordering warnings remain; they did not prevent signature verification, parsing, or conversion.
- **Clean exports:** Downloaded APKs/AAB contain neither `opencode.json` nor test scripts (`B-005`). Gradle fallback restoration avoided the Maven 429 recurrence (`B-004`).
- **P0 result:** Phone acceptance, local/CI validation, both APKs, AAB, and release signing are complete. No open P0 code/build/signing blocker remains.

### Completed Follow-up — 2026-11-25
- The user installed Phase 1, explicitly approved it as working, and reported approximately 7–10 FPS on LOW, MEDIUM, and HIGH on a POCO M6 Pro 5G/6 GB. Functional sign-off is complete; the performance defect is tracked separately as `B-006` and is being addressed in P2.

### Definition of Done (Every Phase)
1. **PASS:** `bash tools/validate.sh` passes locally and in CI (import, `--check-only` on all `.gd`, headless boot test).
2. **PASS WITH `B-003`:** Screenshots render under Xvfb/Lavapipe and initial local visuals were inspected; the latest CI PNGs passed integrity/dimension checks. The P2 shutdown warning remains open.
3. **PASS:** GitHub Actions CI builds STANDARD APK, ULTRA APK, and AAB cleanly (`gh run watch 45548311788 --exit-status`).
4. **PASS:** User approved Phase 0 on Android on 2026-11-25; release-signed CI artifacts were downloaded and verified in run `45548311788` (`P0.11`).
5. **PASS:** `docs/ROADMAP.md`, `docs/CHANGELOG.md`, `CREDITS.md`, and `docs/LIMITS.md` reconciled with verified results on `dev`.

---

## Completed Phase: P1 — Character Controller, Camera, Touch Controls

### Checklist
- [x] `P1.1` Modular `player/player.tscn` + `player/player_controller.gd` using Jolt `CharacterBody3D`; old capsule/controller code removed from `world/main.gd`
- [x] `P1.2` Two original switchable protagonists, Kian Cross and Sera Vale, with distinct materials and articulated procedural rigs (`player/protagonist_visual.gd`)
- [x] `P1.3` Camera-relative idle/walk/sprint/crouch/jump/fall/vault states, acceleration/deceleration, coyote time, jump buffering, crouch clearance, and real ray-checked vault traversal
- [x] `P1.4` Independent smoothed third-person `SpringArm3D` camera with sphere collision, player exclusion, yaw/pitch limits, and target reset (`player/third_person_camera.gd`)
- [x] `P1.5` Dynamic touch thumbstick, swipe orbit, sprint lock, crouch/stand, protagonist switch, and contextual JUMP/VAULT HUD
- [x] `P1.6` Keyboard and gamepad parity: WASD/arrows + left stick, mouse/right-stick camera, Space/A action, C/B crouch, Tab/Y switch, Shift/left-stick sprint
- [x] `P1.7` `tests/player_test.gd`: walk, sprint, crouch, jump, vault completion, protagonist switching, camera obstruction, and standing-clearance regressions; all eight checks pass
- [x] `P1.8` STANDARD and ULTRA screenshots generated in CI and passed PNG/dimension/nonblank checks; fresh local visual inspection remains unavailable (`L-005`). Nonfatal probe shutdown warning remains `B-003`
- [x] `P1.9` Local validation/Android builds, release-signed green CI, and documentation passed; user approved Phase 1 functionality on a physical phone on 2026-11-25 and reported `B-006`

### Verification Report — 2026-11-25
- **Local:** `bash tools/validate.sh` passes 14 scripts, seven-autoload boot, Jolt/25-chunk checks, and all eight character/camera tests. Sequential local STANDARD APK (`80282753` bytes), ULTRA APK (`80282781` bytes), and debug AAB (`28377390` bytes) passed signature/archive checks before the export-content cleanup.
- **Clean local export:** After `B-005`, a sequential validation + AAB build passed; archive inspection confirmed no `opencode.json` or test scripts and valid CRCs.
- **CI:** Run `45548311788` passed validation, both renderer captures, all release-signed Android builds, and downloadable-artifact verification. The AAB also generated a valid universal APK set with bundletool.
- **Visual/device result:** Both CI PNGs are valid 1280×720 nonblank images. The user explicitly accepted the Phase 1 build on a physical phone on 2026-11-25; its 7–10 FPS report is open as `B-006`, not counted as successful performance validation.

## Active Phase: P2 — Sky, Clouds, Weather, Time of Day, Lighting

### Checklist
- [x] `P2.1` Record Phase 1 device acceptance and diagnose `B-006`: requested quality was not consistently applied, Android auto-detection selected HIGH from CPU cores, shadow atlases were not applied, and unbatched geometry/per-pixel effects dominated the software baseline
- [x] `P2.2` Rebuild LOW/MEDIUM/HIGH budgets: 0.50/0.70/0.85 base scale, 30/45/60 FPS caps, real 512/1024/2048 shadow atlases, tiered lights/fog/glow/probes/AA/water/detail, and conservative STANDARD Android auto-detection
- [x] `P2.3` Batch immutable scenery into spatial MultiMeshes while retaining every independent collider; budget 163 instances into 42 batches and preserve vault/player regression tests
- [x] `P2.4` Add deterministic preset CLI selection, actual render-scale telemetry, and a structural performance suite to all seven validation stages
- [x] `P2.5` Add original quarter-resolution procedural sky/cloud/sun/star shading with tiered radiance and no time-driven reflection rebuild loop
- [x] `P2.6` Render final LOW/HIGH STANDARD and HIGH ULTRA screenshots under Lavapipe; LOW improved from 4 to 15 FPS and HIGH from 2 to 3 FPS at 1280×720. These are software-render comparisons, not phone FPS claims
- [x] `P2.7` Built version `0.3.0-p2`/versionCode 2 as STANDARD, ULTRA, and AAB; green release CI run `45742203868` and downloaded-artifact verification passed
- [ ] `P2.8` Obtain physical-phone LOW/MEDIUM/HIGH FPS and visual results; iterate until the performance defect has measured improvement
- [ ] `P2.9` Full continuous 24-hour sun/moon cycle with renderer-aware atmospheric lighting and smooth phase interpolation
- [ ] `P2.10` Layered volumetric cloud raymarch, scattering/silver lining, aerial perspective, and quality fallbacks beyond the current procedural cloud foundation
- [ ] `P2.11` Rain, storms, wetness/puddles/ripples, wind, lightning, fog, heat haze, and per-weather grading

### Current Performance Evidence
| Capture | FPS | Draw calls | Triangles | Actual 3D scale | Shadow atlas |
|---|---:|---:|---:|---:|---:|
| Phase 1 LOW baseline | 4 | 153 | 15,474 | 0.670 | 1024 (requested; not applied) |
| Phase 2 LOW | 15 | 60 | 6,230 | 0.500 | 512 |
| Phase 1 HIGH baseline | 2 | 187 | 45,292 | 1.000 | 4096 (requested; not applied) |
| Phase 2 HIGH / STANDARD | 3 | 106 | 17,738 | 0.850 | 2048 |
| Phase 2 HIGH / ULTRA | 1 | 215 | 17,746 | 0.850 | 2048 |

- Final local PNGs passed integrity, 1280×720 dimension, and nonblank pixel-statistic checks. Fresh image viewing remains unavailable; CI must repeat all three captures.
- Sequential local Android builds passed: STANDARD APK `80285766` bytes, ULTRA APK `80285790` bytes, and AAB `28380094` bytes. Both debug APKs passed v2 signature checks and report versionCode 2/version `0.3.0-p2`; all archives passed CRC/content checks. The debug AAB passed bundletool validation and universal-APK generation.
- **Release CI:** [run `45742203868`](https://github.com/shanfxr3-cmyk/coastline-vicio-bay/actions/runs/45742203868), commit `27e5e08`, passed validation, all three captures, and release-signed builds. Downloaded STANDARD APK (`74659765` bytes) and ULTRA APK (`74659781` bytes) passed v2 verification with release-certificate SHA-256 `1d1b4c635840b12661d329de119e37691939107ae9750f50935bf7fde55c293b`; AAB (`26630305` bytes) passed JAR/ZIP verification, bundletool validation, and universal-APK generation. All archives exclude tooling/tests, and all CI PNGs passed integrity/dimension/nonblank checks.
- Phase 2 is not complete: its first milestone is an optimized, testable atmosphere foundation. Weather and a continuous time cycle are not represented as shipped.

### Resume Steps After Interruption
1. Ask the user to install STANDARD from run `45742203868` (or the latest green documentation run), compare LOW first on `0.3.0-p2`, and report the on-screen FPS/draw calls/resolution from **DBG**.
2. If LOW remains near 10 FPS, profile GPU versus CPU on the physical device before adding further effects; do not claim `B-006` fixed from Lavapipe numbers.
3. After measurable device improvement, continue the remaining P2 atmosphere/weather items in order.

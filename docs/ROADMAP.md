# ROADMAP — Coastline: Vicio Bay

> **Session Resume Protocol**: Read `docs/STUDIO_BIBLE.md`, `docs/ROADMAP.md`, `docs/BUGS.md`, and `docs/LIMITS.md` first, then continue from the first `[ ]` / `IN PROGRESS` item below.

## Phase Status Overview

| Phase | Name | Status | Target |
|---|---|---|---|
| **P0** | Build Pipeline, Skeleton, Touch Demo, CI (STANDARD / ULTRA / AAB) | `PHONE ACCEPTED` | User approved on Android; release CI verification carried forward |
| **P1** | Character Controller, Camera, Touch Controls | `IN PROGRESS` | On-foot locomotion + camera rig |
| **P2** | Sky, Clouds, Weather, Time of Day, Lighting | `PENDING` | 24h cycle, volumetric clouds, rain/wetness |
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

## Active Phase: P0 — Build Pipeline, Skeleton, Touch Demo, CI

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
- [ ] `P0.11` User confirmed all three signing secrets were added on 2026-11-25; verify the next pushed CI run logs `Using release signing keystore` and validate its release-signed artifacts
- [x] `P0.12` User installed the STANDARD APK on a physical Android phone, reported that it “runs very good,” and explicitly approved starting Phase 1 on 2026-11-25; expanded Phase 1 controls will receive a fresh device check

### Verification Report — 2026-11-24
- **Local validation:** `bash tools/validate.sh` passed: 10 scripts, seven autoloads, Jolt Physics, 25 chunks, seven audio buses.
- **Local repeatable build:** STANDARD APK (`80256019` bytes), ULTRA APK (`80256047` bytes), and debug AAB (`28349954` bytes) built sequentially without contamination. Both APK signatures and the AAB archive were verified.
- **Local release path:** `build/coastline-vicio-bay-release.aab` (`26599604` bytes) built using a keystore outside the repository; `jarsigner -verify` reported `jar verified` (expected self-signed/timestamp warnings).
- **Green CI:** [run `45389714024`](https://github.com/shanfxr3-cmyk/coastline-vicio-bay/actions/runs/45389714024), commit `f30d84a`, both jobs successful. Downloaded artifacts were signature/archive checked: STANDARD APK `80255783` bytes, ULTRA APK `80255811` bytes, AAB `28349725` bytes.
- **Signing status:** CI logs explicitly say `Release keystore secrets not set; using debug signing.` These artifacts are for testing, not Play publication.
- **Screenshot:** Latest CI PNG is a valid 1280×720 image and earlier local renders passed visual inspection. Nonfatal shutdown warning is tracked as `B-003`; this session could not perform a fresh image review.
- **Device status:** No physical phone is attached, so launch, touch, FPS, thermals, and driver compatibility remain unverified (`L-005`). There are no open code/build P0 blockers.

### Exact Next Steps
1. The user has added all signing secrets. The integration token cannot call workflow dispatch (HTTP 403), so the next Phase 1 push will trigger CI; inspect its build log for `Using release signing keystore`, then mark `P0.11` complete.
2. Physical STANDARD APK launch/operation is accepted by the user. Do not request another Phase 0 installation; request only the expanded Phase 1 control/ULTRA check when the new APK is ready.
3. Continue from the active Phase 1 checklist below. Current code compiles and all eight character/camera physics tests pass; the vault edge-collision defect was fixed with a longer validated landing distance.

### Definition of Done (Every Phase)
1. **PASS:** `bash tools/validate.sh` passes locally and in CI (import, `--check-only` on all `.gd`, headless boot test).
2. **PASS WITH `B-003`:** Screenshots render under Xvfb/Lavapipe and local visuals were inspected; the latest CI PNG passed integrity/dimension checks. The P2 shutdown warning remains open.
3. **PASS:** GitHub Actions CI builds STANDARD APK, ULTRA APK, and AAB cleanly (`gh run watch 45389714024 --exit-status`).
4. **PHONE ACCEPTED / SIGNING CI PENDING:** User approved the Android build on 2026-11-25; secrets are added and the next pushed run must confirm release signing (`P0.11`).
5. **PASS:** `docs/ROADMAP.md`, `docs/CHANGELOG.md`, `CREDITS.md`, and `docs/LIMITS.md` reconciled with verified results on `dev`.

---

## Active Phase: P1 — Character Controller, Camera, Touch Controls

### Checklist
- [x] `P1.1` Modular `player/player.tscn` + `player/player_controller.gd` using Jolt `CharacterBody3D`; old capsule/controller code removed from `world/main.gd`
- [x] `P1.2` Two original switchable protagonists, Kian Cross and Sera Vale, with distinct materials and articulated procedural rigs (`player/protagonist_visual.gd`)
- [x] `P1.3` Camera-relative idle/walk/sprint/crouch/jump/fall/vault states, acceleration/deceleration, coyote time, jump buffering, crouch clearance, and real ray-checked vault traversal
- [x] `P1.4` Independent smoothed third-person `SpringArm3D` camera with sphere collision, player exclusion, yaw/pitch limits, and target reset (`player/third_person_camera.gd`)
- [x] `P1.5` Dynamic touch thumbstick, swipe orbit, sprint lock, crouch/stand, protagonist switch, and contextual JUMP/VAULT HUD
- [x] `P1.6` Keyboard and gamepad parity: WASD/arrows + left stick, mouse/right-stick camera, Space/A action, C/B crouch, Tab/Y switch, Shift/left-stick sprint
- [x] `P1.7` `tests/player_test.gd`: walk, sprint, crouch, jump, vault completion, protagonist switching, camera obstruction, and standing-clearance regressions; all eight checks pass
- [ ] `P1.8` STANDARD and ULTRA screenshots generated; fresh visual/device review pending because this session has no image-viewing capability. Nonfatal probe shutdown warning remains `B-003`
- [ ] `P1.9` Final local validation/Android builds, release-signed green CI, docs, and user Phase 1 phone QA

### Resume Steps After Interruption
1. Run `bash tools/validate.sh`; expected `PLAYER_TEST_PASS` covers eight checks. If vault regresses, reproduce near `VaultPracticeBarrier` at `(-42, 0.425, 1.45)` and keep collision enabled.
2. Review `git diff`, then commit/push the Phase 1 implementation. Inspect the new CI run for release signing to close `P0.11` and confirm all three Android artifacts plus both Phase 1 screenshots.
3. Build/test Android locally, reconcile CHANGELOG/LIMITS/BUGS/README, and request one Phase 1 phone check for movement, sprint, crouch, vault, switching, camera collision, and ULTRA compatibility.

## Next Up After P1: Phase 2 — Sky, Clouds, Weather, Time of Day, Lighting
- Full 24-hour sun/moon cycle and renderer-aware atmospheric lighting
- Custom raymarched cloud sky with half/quarter-resolution fallback
- Rain, storms, wetness/puddles, wind, and per-weather grading

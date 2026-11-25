# ROADMAP — Coastline: Vicio Bay

> **Session Resume Protocol**: Read `docs/STUDIO_BIBLE.md`, `docs/ROADMAP.md`, `docs/BUGS.md`, and `docs/LIMITS.md` first, then continue from the first `[ ]` / `IN PROGRESS` item below.

## Phase Status Overview

| Phase | Name | Status | Target |
|---|---|---|---|
| **P0** | Build Pipeline, Skeleton, Touch Demo, CI (STANDARD / ULTRA / AAB) | `COMPLETE` | Phone accepted + release-signed CI verified |
| **P1** | Character Controller, Camera, Touch Controls | `AWAITING PHONE QA` | Implementation, tests, and release CI complete; device sign-off pending |
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

### Exact Next Steps
1. Request one Phase 1 STANDARD phone check from run `45548311788`; do not request another Phase 0 installation.
2. Record the user's movement, sprint, crouch, jump/vault, switching, camera-collision, and ULTRA results in `P1.8`/`P1.9`.
3. Start Phase 2 only after fresh Phase 1 device acceptance.

### Definition of Done (Every Phase)
1. **PASS:** `bash tools/validate.sh` passes locally and in CI (import, `--check-only` on all `.gd`, headless boot test).
2. **PASS WITH `B-003`:** Screenshots render under Xvfb/Lavapipe and initial local visuals were inspected; the latest CI PNGs passed integrity/dimension checks. The P2 shutdown warning remains open.
3. **PASS:** GitHub Actions CI builds STANDARD APK, ULTRA APK, and AAB cleanly (`gh run watch 45548311788 --exit-status`).
4. **PASS:** User approved Phase 0 on Android on 2026-11-25; release-signed CI artifacts were downloaded and verified in run `45548311788` (`P0.11`).
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
- [ ] `P1.8` STANDARD and ULTRA screenshots generated in CI and passed PNG/dimension/nonblank checks; fresh visual/device review remains because this session has no image-viewing capability. Nonfatal probe shutdown warning remains `B-003`
- [ ] `P1.9` Local validation/Android builds, release-signed green CI, and documentation pass; fresh user Phase 1 phone QA remains

### Verification Report — 2026-11-25
- **Local:** `bash tools/validate.sh` passes 14 scripts, seven-autoload boot, Jolt/25-chunk checks, and all eight character/camera tests. Sequential local STANDARD APK (`80282753` bytes), ULTRA APK (`80282781` bytes), and debug AAB (`28377390` bytes) passed signature/archive checks before the export-content cleanup.
- **Clean local export:** After `B-005`, a sequential validation + AAB build passed; archive inspection confirmed no `opencode.json` or test scripts and valid CRCs.
- **CI:** Run `45548311788` passed validation, both renderer captures, all release-signed Android builds, and downloadable-artifact verification. The AAB also generated a valid universal APK set with bundletool.
- **Visual/device limit:** Both CI PNGs are valid 1280×720 nonblank images, but no fresh visual inspection or physical-device performance claim is made (`L-005`, `B-003`).

### Resume Steps After Interruption
1. Install `coastline-standard-apk` from green run `45548311788`; test movement, sprint lock, crouch/stand, jump, the low-barrier VAULT prompt, Kian/Sera switching, and camera pull-in near walls.
2. On a flagship Vulkan phone, repeat launch/basic controls with `coastline-ultra-apk`; report any black screen, clipping, touch, or renderer issue.
3. Record the user's report in `P1.8`/`P1.9`, `BUGS.md`, and `LIMITS.md`. If accepted, mark Phase 1 complete and begin Phase 2; otherwise fix the reported defect before proceeding.

## Next Up After P1: Phase 2 — Sky, Clouds, Weather, Time of Day, Lighting
- Full 24-hour sun/moon cycle and renderer-aware atmospheric lighting
- Custom raymarched cloud sky with half/quarter-resolution fallback
- Rain, storms, wetness/puddles, wind, and per-weather grading

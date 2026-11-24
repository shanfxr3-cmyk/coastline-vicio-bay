# ROADMAP — Coastline: Vicio Bay

> **Session Resume Protocol**: Read `docs/STUDIO_BIBLE.md`, `docs/ROADMAP.md`, `docs/BUGS.md`, and `docs/LIMITS.md` first, then continue from the first `[ ]` / `IN PROGRESS` item below.

## Phase Status Overview

| Phase | Name | Status | Target |
|---|---|---|---|
| **P0** | Build Pipeline, Skeleton, Touch Demo, CI (STANDARD / ULTRA / AAB) | `AWAITING USER QA` | CI green; signing secrets + phone sign-off pending |
| **P1** | Character Controller, Camera, Touch Controls | `PENDING` | On-foot locomotion + camera rig |
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
- [ ] `P0.11` **User secrets step:** add `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_ALIAS`, and `ANDROID_KEYSTORE_PASSWORD`, rerun `dev` CI, and confirm release-signed artifacts (current run is explicitly debug-signed)
- [ ] `P0.12` **User phone step:** install STANDARD APK on a physical arm64 Android phone; verify launch, lit scene, joystick movement, swipe orbit, JUMP, TOD, QUAL, and DBG; then test ULTRA on a capable flagship and record results

### Verification Report — 2026-11-24
- **Local validation:** `bash tools/validate.sh` passed: 10 scripts, seven autoloads, Jolt Physics, 25 chunks, seven audio buses.
- **Local repeatable build:** STANDARD APK (`80256019` bytes), ULTRA APK (`80256047` bytes), and debug AAB (`28349954` bytes) built sequentially without contamination. Both APK signatures and the AAB archive were verified.
- **Local release path:** `build/coastline-vicio-bay-release.aab` (`26599604` bytes) built using a keystore outside the repository; `jarsigner -verify` reported `jar verified` (expected self-signed/timestamp warnings).
- **Green CI:** [run `45389714024`](https://github.com/shanfxr3-cmyk/coastline-vicio-bay/actions/runs/45389714024), commit `f30d84a`, both jobs successful. Downloaded artifacts were signature/archive checked: STANDARD APK `80255783` bytes, ULTRA APK `80255811` bytes, AAB `28349725` bytes.
- **Signing status:** CI logs explicitly say `Release keystore secrets not set; using debug signing.` These artifacts are for testing, not Play publication.
- **Screenshot:** Latest CI PNG is a valid 1280×720 image and earlier local renders passed visual inspection. Nonfatal shutdown warning is tracked as `B-003`; this session could not perform a fresh image review.
- **Device status:** No physical phone is attached, so launch, touch, FPS, thermals, and driver compatibility remain unverified (`L-005`). There are no open code/build P0 blockers.

### Exact Next Steps
1. Signing material for this handoff is outside the repo in `/tmp/opencode/coastline-release-signing/`: `ANDROID_KEYSTORE_BASE64.txt`, `alias.txt` (`coastline_release`), and `password.txt`. Add those values as GitHub Actions repository secrets using `README.md`; never commit or paste them into chat. Back up the keystore securely. If temporary files disappear, generate a new key only if no prior upload key needs preserving.
2. After saving secrets, run `gh workflow run build.yml --ref dev`, identify the new run with `gh run list --branch dev --limit 1`, then `gh run watch <new-run-id> --exit-status`. Confirm logs say `Using release signing keystore` before marking `P0.11` complete.
3. Complete `P0.12` from the STANDARD artifact at the green run above. Record pass/fail results here. Only after `P0.11` and `P0.12` pass, change P0 to `DONE` and begin P1; otherwise fix the reported issue first.

### Definition of Done (Every Phase)
1. **PASS:** `bash tools/validate.sh` passes locally and in CI (import, `--check-only` on all `.gd`, headless boot test).
2. **PASS WITH `B-003`:** Screenshots render under Xvfb/Lavapipe and local visuals were inspected; the latest CI PNG passed integrity/dimension checks. The P2 shutdown warning remains open.
3. **PASS:** GitHub Actions CI builds STANDARD APK, ULTRA APK, and AAB cleanly (`gh run watch 45389714024 --exit-status`).
4. **PENDING:** Physical-phone QA and release-secret rerun (`P0.11`/`P0.12`); no open code/build P0 blocker.
5. **PASS:** `docs/ROADMAP.md`, `docs/CHANGELOG.md`, `CREDITS.md`, and `docs/LIMITS.md` reconciled with verified results on `dev`.

---

## Next Up After P0: Phase 1 — Character Controller, Camera, Touch Controls
- Implement dual-protagonist base rig & procedural character mesh/capsule placeholder upgrade
- Third-person spring-arm camera with collision avoidance, smooth damping, and touch swipe orbit
- On-foot locomotion state machine (idle, walk, sprint, jump, vault, crouch) using Jolt `CharacterBody3D`
- Touch-first HUD refinement (dynamic virtual thumbstick, sprint lock, jump/vault contextual button, gamepad parity)

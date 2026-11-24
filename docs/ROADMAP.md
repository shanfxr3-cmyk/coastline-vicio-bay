# ROADMAP — Coastline: Vicio Bay

> **Session Resume Protocol**: Read `docs/STUDIO_BIBLE.md`, `docs/ROADMAP.md`, `docs/BUGS.md`, and `docs/LIMITS.md` first, then continue from the first `[ ]` / `IN PROGRESS` item below.

## Phase Status Overview

| Phase | Name | Status | Target |
|---|---|---|---|
| **P0** | Build Pipeline, Skeleton, Touch Demo, CI (STANDARD / ULTRA / AAB) | `IN PROGRESS` | Local APK + Green CI |
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
- [ ] `P0.2` Codespace & reproducible toolchain (`tools/setup_codespace.sh`, `.devcontainer/devcontainer.json`): Godot 4 stable, export templates, JDK 17, Android SDK, Blender headless, ffmpeg, SoX, ImageMagick, Python libs (`numpy`, `Pillow`, `trimesh`), `mesa-vulkan-drivers` (lavapipe), `xvfb`
- [ ] `P0.3` Validation & rendering tools (`tools/validate.sh`, `tools/screenshot.sh`, `tools/fetch_assets.py`, `assets/manifest.json`)
- [ ] `P0.4` Godot 4 project skeleton (`project.godot`, `export_presets.cfg`, Jolt physics, ETC2/ASTC, `com.coastline.viciobay`, folders `/core /world /player /vehicles /ai /weapons /ui /audio /cinematics /missions /narrative /shaders /assets /tools /docs /tests`)
- [ ] `P0.5` Autoloads (`GameState`, `EventBus`, `SaveSystem`, `Settings`, `AudioBus`, `Streaming`, `Debug`)
- [ ] `P0.6` Debug overlay (FPS, frame ms, draw calls, triangles, VRAM, RAM, streaming & physics stats)
- [ ] `P0.7` Lit 3D coastal prototype scene + working touch controls (virtual joystick + swipe look + camera orbit + renderer/preset badge)
- [ ] `P0.8` Local `tools/validate.sh` pass + `tools/screenshot.sh` visual inspection + local Android APK build
- [ ] `P0.9` `.github/workflows/build.yml` (STANDARD APK, ULTRA APK, Release AAB, cached Godot/templates/Gradle/imported resources) + keystore setup instructions
- [ ] `P0.10` Push to `dev`, `gh run watch` green CI for STANDARD, ULTRA, and AAB, update docs, commit & report

### Definition of Done (Every Phase)
1. `bash tools/validate.sh` passes cleanly (import, `--check-only` on all `.gd`, headless boot test).
2. `bash tools/screenshot.sh` renders cleanly under xvfb/lavapipe and visuals are verified.
3. GitHub Actions CI builds `STANDARD` APK, `ULTRA` APK, and `AAB` cleanly (`gh run watch`).
4. QA checklist passes with no open P0 blockers.
5. `docs/ROADMAP.md`, `docs/CHANGELOG.md`, `CREDITS.md`, and `docs/LIMITS.md` updated and committed on `dev`.

---

## Next Up After P0: Phase 1 — Character Controller, Camera, Touch Controls
- Implement dual-protagonist base rig & procedural character mesh/capsule placeholder upgrade
- Third-person spring-arm camera with collision avoidance, smooth damping, and touch swipe orbit
- On-foot locomotion state machine (idle, walk, sprint, jump, vault, crouch) using Jolt `CharacterBody3D`
- Touch-first HUD refinement (dynamic virtual thumbstick, sprint lock, jump/vault contextual button, gamepad parity)

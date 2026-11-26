# CHANGELOG — Coastline: Vicio Bay

All notable changes to the project are documented in this file.

## [Unreleased] — Phase 2 (Optimisation & Atmosphere Foundation)
- Recorded user Phase 1 device acceptance and the 7–10 FPS regression on a POCO M6 Pro 5G/6 GB (`B-006`); performance acceptance remains pending.
- Reworked LOW/MEDIUM/HIGH budgets and made them authoritative during both automatic detection and manual changes; Android STANDARD now defaults to LOW.
- Added actual shadow-atlas application, 30/45/60 FPS caps, real render-scale telemetry, preset-specific MSAA/FXAA/FSR2, and optional Android STANDARD adaptive resolution.
- Batched 163 immutable scenery instances into 42 spatial MultiMesh batches without removing collision bodies; added quality-scaled water, palms, roads, detail distance, streetlights, fog, glow, and probes.
- Added original quarter-resolution procedural sky/cloud/sun/star shading with tiered radiance and cheaper LOW water/asphalt shader paths.
- Added deterministic `--quality=low|medium|high` screenshot selection and structural performance tests to the seven-stage validator.
- Local validation passes 16 scripts, boot, all eight gameplay regressions, and the rendering-budget suite.
- Lavapipe LOW improved from 4 to 15 FPS and HIGH from 2 to 3 FPS at 1280×720; final STANDARD LOW/HIGH and ULTRA HIGH PNGs passed integrity/dimension/nonblank checks. Phone FPS remains unverified.
- Sequential local STANDARD APK (`80285766` bytes), ULTRA APK (`80285790` bytes), and AAB (`28380094` bytes) passed signature/archive/content checks; the debug AAB passed bundletool validation and universal-APK generation.
- Version advanced to `0.3.0-p2`/versionCode 2; CI now captures three Phase 2 preset/renderer images. Full 24-hour cycling and weather remain unfinished.

## [Unreleased] — Phase 1 (Functionally Complete; Performance Follow-up in P2)
- Added modular Jolt `CharacterBody3D` locomotion with idle, walk, sprint, crouch, jump, fall, and collision-tested vault states.
- Added switchable original protagonists Kian Cross and Sera Vale with articulated procedural rigs and distinct materials.
- Added smoothed `SpringArm3D` third-person camera collision, touch/mouse/right-stick orbit, and keyboard/gamepad parity.
- Expanded the touch HUD with sprint lock, crouch/stand, protagonist switching, and contextual JUMP/VAULT feedback.
- Added eight physics-level character/camera regression checks and dual-renderer Phase 1 screenshot CI.
- Fixed vault landing on the barrier edge by extending the validated traversal distance; removed duplicate legacy HUD keyboard input.
- Isolated the nonfatal seven-texture shutdown warning to `ReflectionProbe` rendering under Godot 4.7.2/Lavapipe (`B-003`).
- User approved Phase 0 on a physical Android phone and added the release-signing secrets on 2026-11-25.
- Fixed Gradle fallback restoration across project/version changes after Maven Central HTTP 429 (`B-004`).
- Excluded local agent configuration and test-only scripts from shipping Android exports (`B-005`).
- Green CI run `45548311788` produced release-signed STANDARD APK (`74648792` bytes), ULTRA APK (`74648808` bytes), and AAB (`26618900` bytes).
- Downloaded APKs passed v2 release-signature and arm64/package checks; the AAB passed JAR/ZIP verification, bundletool validation, and universal-APK conversion.
- Both 1280×720 CI screenshots passed integrity/nonblank checks. User subsequently approved Phase 1 functionality on a phone but reported 7–10 FPS, now tracked as `B-006`.

## [Unreleased] — Phase 0 (Complete)

### Added
- Studio governance, original art direction, roadmap, limits, bug/debt logs, and reproducible Codespace/devcontainer setup.
- Godot 4.7.2 text-only project with Jolt physics, seven autoloads, save/settings/audio/streaming systems, and telemetry overlay.
- Procedural Bayfront coastal preview with glass towers, LED materials, water, wet asphalt, three lighting presets, touch joystick/swipe/jump controls, and Low/Medium/High quality controls.
- Headless validation, Vulkan screenshot tooling, hash-pinned asset-manifest validation, Android APK/AAB builder, and GitHub Actions artifact pipeline.
- STANDARD/Mobile and ULTRA/Forward+ builds, plus automatic release signing when credentials are supplied and an explicit debug-signing fallback.

### Fixed
- Standalone GDScript checks now resolve autoloads without relying on editor registration order.
- STANDARD uses supported bilinear 3D scaling; FSR2 is limited to ULTRA/Forward+.
- Gradle memory is capped for Codespace/CI containers, and generated Android files are excluded from Godot imports during repeated exports.
- CI workflow parsing, Godot cache location, Android SDK setup, and incomplete local `ANDROID_HOME` fallback.

### Verified
- Local validation: 10 GDScript files, seven autoloads, Jolt, 25 streaming chunks, and seven audio buses.
- Local sequential STANDARD APK, ULTRA APK, debug AAB, and separate release-signed AAB builds; APK signatures and AAB archives checked.
- GitHub Actions run `45389714024`: both jobs green; STANDARD APK, ULTRA APK, AAB, and screenshot artifacts uploaded, downloaded, and technically verified.
- The initial run's artifacts were debug-signed. The user subsequently accepted Phase 0 on a physical Android phone, and run `45548311788` superseded them with verified release-signed artifacts.

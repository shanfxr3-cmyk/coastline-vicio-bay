# CHANGELOG — Coastline: Vicio Bay

All notable changes to the project are documented in this file.

## [Unreleased] — Phase 1 (In Progress)
- Added modular Jolt `CharacterBody3D` locomotion with idle, walk, sprint, crouch, jump, fall, and collision-tested vault states.
- Added switchable original protagonists Kian Cross and Sera Vale with articulated procedural rigs and distinct materials.
- Added smoothed `SpringArm3D` third-person camera collision, touch/mouse/right-stick orbit, and keyboard/gamepad parity.
- Expanded the touch HUD with sprint lock, crouch/stand, protagonist switching, and contextual JUMP/VAULT feedback.
- Added eight physics-level character/camera regression checks and dual-renderer Phase 1 screenshot CI.
- Fixed vault landing on the barrier edge by extending the validated traversal distance; removed duplicate legacy HUD keyboard input.
- Isolated the nonfatal seven-texture shutdown warning to `ReflectionProbe` rendering under Godot 4.7.2/Lavapipe (`B-003`).
- User approved Phase 0 on a physical Android phone and added the release-signing secrets on 2026-11-25.

## [Unreleased] — Phase 0 (Phone Accepted / Signing CI Pending)

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
- Physical-phone launch/touch/performance QA and release-signed CI rerun remain pending; current CI artifacts are debug-signed.

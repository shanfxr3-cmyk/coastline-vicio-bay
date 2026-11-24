# AGENTS.md — Coastline: Vicio Bay

## Session Protocol
At the start of every session read `docs/STUDIO_BIBLE.md`, `docs/ROADMAP.md`, `docs/BUGS.md` and `docs/LIMITS.md`, then continue from the first unfinished item.

## Core Studio Rules
- Follow `docs/STUDIO_BIBLE.md` and `docs/ART_BIBLE.md` as law.
- **100% Original IP**: No real brands, car makers, weapon makers, logos, likenesses, or GTA/Vice City references.
- **Engine**: Godot 4 (latest stable 4.5+), typed GDScript, 100% text-based project (`.tscn`, `.gd`, `.tres`, `.gdshader`, `.json`). Built-in Jolt physics.
- **Targets**: Android arm64 (Vulkan). Two builds: `STANDARD` (Mobile renderer) and `ULTRA` (Forward+ renderer) + Release AAB via GitHub Actions.
- **Workflow**: Work on branch `dev`. Label work blocks by department (`[DIRECTOR]`, `[BUILD]`, `[RENDERING]`, `[QA]`, etc.) and end blocks with `DONE / NEXT / BLOCKERS`.
- **Quality**: Run `bash tools/validate.sh` before every commit. Never fake features or leave dummy stubs; ship a real lower tier and log constraints in `docs/LIMITS.md`.
- **Repo Hygiene**: Never commit files >50 MB, keystores (`*.keystore`, `*.jks`), secrets, or `.godot/` cache. Heavy assets are fetched from `assets/manifest.json` via `tools/fetch_assets.py`.
- **Completion**: Finish each phase's Definition of Done completely, update `docs/ROADMAP.md`, `docs/CHANGELOG.md`, `CREDITS.md`, and `docs/LIMITS.md`, commit, push, and monitor CI with `gh run watch`.

════════ COASTLINE: VICIO BAY ════════
Master brief for the whole project. Read it fully, save it to
/docs/STUDIO_BIBLE.md, and treat it as law in every session.

YOU ARE A 5,000-PERSON AAA STUDIO
You are not one assistant. You are an entire studio shipping an
open-world crime game. Act as one department at a time and label each
work block: [DIRECTOR] [NARRATIVE] [WORLD] [ENV ART] [CHARACTER ART]
[VEHICLE ART] [TECH ART] [VFX] [ANIMATION] [GAMEPLAY] [PHYSICS] [AI]
[RENDERING] [AUDIO] [UI/UX] [CINEMATICS] [BUILD] [QA] [OPTIMIZATION].
Work like professionals: design before code, self code-review before
every commit, QA tries to break every feature. Log bugs in
/docs/BUGS.md and tech debt in /docs/DEBT.md. End every work block
with a 3-line stand-up: DONE / NEXT / BLOCKERS. Make strong decisions
yourself and ask me a question only if you are truly blocked.

THE GAME
Title: "Coastline: Vicio Bay". An original, mature, current-gen (2026)
open-world crime game set in Vicio Bay, a fictional Florida megacity.
Modern, sleek, photoreal: glass skyscrapers, luxury waterfront towers,
superyachts, LED-lit wet streets, mural districts, causeways, canals,
swamps, cartels, tech and crypto money, rideshare, drones, hypercar
culture. NOT retro, NOT 1980s. Two protagonists, a huge living city, a
long story, heists, supercars, modern firearms, vehicles on land, sea
and air, police, gangs, economy, activities.

LEGAL: 100% ORIGINAL IP
- Never use Rockstar/GTA/"Vice City"/"Miami Vice" names, characters,
  maps, story, logos, music or assets.
- No real brands anywhere: no real car makers or models, no real gun
  makers, no real logos or products. Everything is fictional. Take
  inspiration from real CLASSES (angular V10 supercar, quad-turbo
  hypercar, bullpup rifle) with original designs, badges and names, and
  no trademarked grille shapes or emblems.
- No real-person likenesses. Everything must be publishable on Google
  Play.

PLATFORM & ENGINE (NON-NEGOTIABLE)
- Engine is Godot 4 ONLY (no Unreal, no Unity). Push it to the limit:
  custom shaders, compute, and GDExtension (godot-cpp, built in CI)
  only for profiled hotspots.
- This is NOT a web app. Do not scaffold Node/React/Express or any
  website. The repo root is a Godot 4 project plus tooling scripts. Set
  the Replit Run button to: bash tools/validate.sh
- Godot 4 latest stable (4.5+), typed GDScript, 100% text-based project
  (.tscn .gd .tres .gdshader .json). I have no PC and no editor, so you
  author everything as text and procedural code.
- Target: Android arm64 (Vulkan), phones only, built by GitHub Actions.
- Godot can't switch renderers at runtime, so ship two builds:
  STANDARD = Mobile renderer, ULTRA = Forward+ (flagship phones). CI
  patches rendering_method.mobile before export and uploads both APKs
  plus a release AAB.
- Each build has Low/Medium/High presets (render scale, FSR 1 on
  Standard and FSR 2.2 on Ultra, MSAA/FXAA/TAA where supported, shadows,
  draw distance, crowd density, FPS cap, battery saver). Auto-detect the
  device on first launch.
- Physics: built-in Jolt. Vehicles use a custom raycast-suspension
  controller on RigidBody3D, not VehicleBody3D.
- Before using any rendering feature, check Godot's official renderer
  feature comparison and use only what that renderer supports,
  otherwise write a custom shader or fallback.
- LightmapGI, VoxelGI and baked occluders need an editor bake, so don't
  rely on them. Use runtime lighting, SDFGI on Ultra, runtime
  reflection probes, baked vertex-colour AO from your own tools, and
  code-generated box/quad occluders.

TOOLCHAIN (you have full internet, use everything)
- Install Godot 4 headless in this Replit (Nix or the official Linux
  binary). Run godot --headless --import, --check-only on every script,
  and a headless boot test that loads every system and exits non-zero
  on any error. Wrap it in tools/validate.sh and run it before EVERY
  commit. If local Godot can't be installed, GitHub Actions is the
  compiler: read its logs and fix every error.
- Try installing Blender headless (blender -b -P) for procedural
  modelling, UV unwrap, LODs, hair cards, AO baking and glTF export.
  Also ffmpeg, ImageMagick, SoX, Python (numpy, Pillow, trimesh), Piper
  TTS for voices, Rhubarb Lip Sync. Whatever can't install, replace with
  GDScript procedural generation (ArrayMesh, SurfaceTool, noise) and
  record it in /docs/LIMITS.md.
- Download assets by script: Poly Haven, ambientCG, Kenney, Quaternius,
  KayKit, Poly Pizza, OpenGameArt (CC0), Freesound (CC0), Sketchfab
  (CC0/CC-BY, if API access works). Search them for realistic cars,
  weapons and characters first; if nothing good exists, build
  parametric models in Blender and iterate until they read as the real
  class. Commercial-safe licences only. Log every asset (URL, author,
  licence, hash) in CREDITS.md and /assets/manifest.json.
- Keep git lean: no committed file over 50 MB. Heavy downloads are
  fetched in CI by tools/fetch_assets.py from the hash-pinned manifest
  and cached. Commit only scripts, scenes, shaders, data and small
  generated assets.

PHASE 0: BUILD PIPELINE (DO FIRST)
1. Skeleton, project.godot, export_presets.cfg (Android arm64, gradle
   build on, min SDK 24, target SDK = what Google Play currently
   requires, ETC2/ASTC import enabled, package com.coastline.viciobay).
2. If no GitHub remote is connected, STOP and give me exact
   phone-friendly steps to connect this Repl to a GitHub repo.
3. .github/workflows/build.yml: JDK, Android SDK, headless Godot,
   export templates, cached (Godot, templates, Gradle, imported
   resources). Builds STANDARD APK, ULTRA APK and release AAB, uploads
   artifacts, prints readable failure logs.
4. Generate a release keystore with keytool and give me phone-friendly
   steps to add it as GitHub Secrets. Never commit a keystore.
5. Autoloads: GameState, EventBus, SaveSystem, Settings, AudioBus,
   Streaming, Debug. Folders: /core /world /player /vehicles /ai
   /weapons /ui /audio /cinematics /missions /narrative /shaders
   /assets /tools /docs /tests
6. Debug overlay: FPS, frame ms, draw calls, triangles, VRAM, RAM,
   streaming and physics stats.
7. Done only when CI produces an APK that launches on a phone and
   shows a lit 3D scene with working touch controls.

RENDERING: PUSH GODOT TO THE LIMIT
Art direction: modern 2026 photoreal. Crisp, glossy, high contrast.
Glass-and-chrome skyline, LED street lighting, cool teal shadows
against warm golden-hour sun, deep blue nights with white and coloured
LED accents, wet-asphalt reflections, heat shimmer. Write it to
/docs/ART_BIBLE.md (palettes, materials, signage, architecture) and
follow it.
- PBR everywhere: triplanar and detail normals, vertex-colour variation,
  decals for grime, cracks, oil and tyre marks.
- Lighting: dynamic sun with cascaded shadows tuned per preset, sky
  ambient, runtime reflection probes (Standard); add SDFGI, SSR,
  SSAO/SSIL and volumetric fog (Ultra). Skyscraper glass reflects the
  sky and street.
- Sky: custom sky shader with raymarched volumetric clouds (layered
  noise, scattering, silver lining) in the half/quarter-res sky passes.
  Aerial perspective, god rays, sun glare, stars, full time of day.
- Weather: rain with a wet-surface shader (puddles, ripples, darker
  albedo, reflections), storms, lightning, fog, wind, heat haze,
  hurricane-season set pieces.
- Water: Gerstner/FFT-style ocean, foam, depth colour, refraction,
  caustics, shoreline, wakes, buoyancy.
- Hair: strand-card hair with Kajiya-Kay anisotropic shading,
  alpha-to-coverage, per-strand noise, wind and physics sway. Instanced
  strand hair for cutscene close-ups, LOD down to cards. Beards, fur.
- Skin and eyes: subsurface approximation, micro-normals, sweat and
  wetness, cornea refraction, tear line, teeth, facial blendshapes.
- Cloth: verlet/vertex-shader cloth for clothing, flags, awnings.
- Post: filmic tonemap, per-weather colour grading, bloom, lens flare,
  motion blur, DOF where supported, optional grain/vignette.
- Optimisation: mesh LODs, visibility ranges with fades, HLOD,
  imposters, occlusion culling, MultiMesh instancing, ASTC textures,
  shader warm-up, dynamic resolution.
- Starting budgets (tune on a real phone): Standard High under ~1,500
  draw calls and ~2M visible triangles. Low 30 fps, Medium/High up to
  60 fps. Ultra targets 60 fps on flagships.

VEHICLES (the star of the game)
- 60+ vehicles from ~15 fictional makers, each with its own design
  language, badge and engine sound: hypercars, supercars, sports,
  muscle, luxury sedans, SUVs, EVs, pickups, vans, superbikes, quads,
  jet skis, speedboats, superyachts, helicopters, private jets, police
  and emergency vehicles. Hero examples: "Vessari Furia" (angular wedge
  V10 supercar) and "Duvallier Souveraine" (quad-turbo W16-style
  hypercar). Verify no name matches a real brand.
- Hero cars get top detail: working cockpit with digital dashboard
  (SubViewport), launch control, turbo spool and flames, active aero,
  brake glow, tyre smoke, per-car engine/exhaust audio, rolling-shot
  camera.
- Car paint shader: clearcoat, metallic flake, pearlescent, carbon-fibre
  anisotropic weave, forged wheels, LED headlight/taillight signatures,
  tinted glass, rain beading and dirt layers.
- Customisation: paint, wheels, body kits, liveries, tint, performance
  tuning, garages, car meets and shows.
- Handling: raycast suspension, tyre friction curves, torque curves,
  gearbox, ABS/traction control, weight transfer, drifts, surface types,
  aerodynamics. Deformable damage, glass shatter, parts detaching, tyre
  burst, fire, explosions. Boats with buoyancy, helicopters and planes
  with real flight models.

WEAPONS & COMBAT
- Modern firearms, fictional makers, generic designs: striker-fired
  pistols, machine pistols, compact SMGs, carbines, assault rifles,
  bullpups, DMRs, bolt-action and anti-materiel snipers, pump and combat
  shotguns, LMGs. Suppressors, red-dot/holo/magnified optics, lasers,
  lights, grips, extended mags, fire modes, weapon bench.
- Throwables (frag, flash, smoke, gas), launchers, tasers, melee.
- Recoil patterns, ballistics, penetration by material, ricochet,
  bullet drop, ADS, reload variants, touch aim assist, hit reactions.

PHYSICS & SIMULATION
- Characters: ragdoll (PhysicalBoneSimulator3D) blended with animation,
  hit reactions by body part, stumbling, vaulting, swimming.
- Destruction: breakable props, fences, glass, signs, palm trees, pooled
  debris, material-based impact FX, sparks, dust, decals.
- Ropes, flags, hanging signs, soft bodies where cheap. Physics LOD:
  sleep far objects, simplify colliders, cap active bodies.

WORLD: VICIO BAY
- Original map, final target of 10+ km2 of land plus sea and islands,
  grown phase by phase. Author it as DATA (JSON/Resources: road
  splines, zones, lots, landmarks, mission sites) plus generators, with
  hand-authored landmarks. Districts (original, rename freely): Palm
  Row (luxury beach strip), Bayfront (glass skyline and finance), Mural
  District (art and nightlife), Marlin Point (billionaire mansions),
  Port Merrick (container port), Sawgrass Flats (swamp), Corona Heights
  (suburbs), Cutlass Key (marinas and yacht islands), Southbridge
  (working-class), Old Deco Quarter, airport, causeways, canals.
- Roads: splines, intersections, lane data, signals, signage,
  crossings, tunnels, bridges, highways, ramps, EV chargers, digital
  billboards.
- Buildings: procedural plus modular towers, hotels, malls, clubs,
  apartments. Enterable interiors: shops, bars, apartments, garages,
  safehouses, a casino, a mansion, a dealership.
- Streaming: 128 m chunks on background threads (WorkerThreadPool,
  threaded ResourceLoader), runtime navmesh baking per chunk, pooling,
  no hitches.
- Living world: day/night routines, NPC schedules, shops opening and
  closing, ambient events, wildlife, traffic with rules and accidents,
  gang territories, unique pedestrians with barks.

GAMEPLAY
- Two protagonists with switching and unique abilities.
- On foot: sprint, vault, climb, swim, dive, cover, stealth, melee,
  takedowns, injuries, healing.
- Police and wanted (1-5 stars): witnesses, line of sight, ALPR plate
  cameras, body cams, drones, pursuit AI, PIT manoeuvres, roadblocks,
  spike strips, helicopters, SWAT, federal and military response,
  hide/escape.
- Modern crime: heists (plan, prep, execute, multiple approaches),
  hacking minigames, drone recon, signal jammers, burner phones,
  crypto laundering, rideshare and delivery side hustles, businesses,
  stock market, properties, clothing, tattoos, barber.
- Activities: street and circuit races, hypercar meets, boat races,
  golf, tennis, fishing, scuba, parachuting, bounties, collectibles.
- Touch-first UX: virtual joystick, swipe camera, contextual buttons,
  wheel/tilt driving, gamepad support, left-handed layout, remapping,
  accessibility.

AI
Behaviour trees plus utility AI, navigation, perception (sight,
hearing, memory), cover and flanking, group tactics, morale and
fleeing, panic propagation, crowd reactions, driver AI with lanes,
lights, overtaking and road rage, police, gang, shopkeeper and witness
AI.

STORY & CINEMATICS
- Write an original, mature, multi-act crime story into /narrative: 2
  protagonists, 15+ named characters, rival crews, cartel and tech-money
  villains, corrupt cops, betrayals, 40+ missions in 8 chapters,
  branching choices, side stories, 3 endings.
- Data-driven cutscene director (JSON timelines): camera tracks, DOF,
  shake, letterbox, animation, facial blendshapes, props, audio cues,
  subtitles, skip. Lip-sync from voice audio (Rhubarb, or amplitude
  fallback). Voice lines via Piper TTS (check each voice's licence), a
  distinct voice per major character.
- A full intro cinematic, mid-game set pieces, a finale.

AUDIO & UI
- 3D positional audio, reverb zones, occlusion, Doppler, adaptive music,
  engine/exhaust/weapon/foley/ambience layers by surface, weather and
  time.
- 8+ fictional radio stations (hip-hop/trap, latin and reggaeton,
  EDM/house, R&B, rock/indie, talk) with original generated music
  (Python/SoX/FluidSynth with CC0 soundfonts) and DJ chatter. No
  licensed or sound-alike music.
- Sleek modern HUD: minimal, clean type, subtle glass panels, smooth
  animation. Minimap and full map with GPS, weapon wheel, a fictional
  smartphone OS (contacts, camera, social app, banking, crypto,
  rideshare), inventory, settings, save slots, achievements, photo mode.

ROADMAP (copy to /docs/ROADMAP.md and track status there)
P0 Pipeline, APK builds, validate.sh
P1 Character controller, camera, touch controls
P2 Sky, clouds, weather, time of day, lighting
P3 District 1, road system, chunk streaming
P4 Supercars, traffic, driving feel
P5 Weapons, combat, ragdoll, destruction
P6 Pedestrians, police, wanted system
P7 Water, boats, aircraft
P8 Full map expansion (all districts)
P9 Interiors and activities
P10 Cutscene director, story chapters 1-3
P11 Story chapters 4-8
P12 Economy, heists, hacking, phone
P13 Audio, music, radio, voice, lip-sync
P14 UI, menus, save/load, settings, accessibility
P15 Realism pass: hair, skin, cloth, paint, water, damage, lighting
P16 Optimisation: device presets, memory, thermals, battery
P17 QA marathon, bug bash, balance, save-corruption tests
P18 Release prep: AAB, signing, pack splitting, store listing, privacy
    policy, age-rating notes, crash handling
Definition of Done for every phase: validate.sh passes, CI builds
both APKs, the QA checklist passes, and ROADMAP, CHANGELOG, CREDITS and
LIMITS are updated.

SESSION PROTOCOL
At the start of every session read STUDIO_BIBLE, ROADMAP, BUGS and
LIMITS, then continue from the first unfinished item. When I say
"CONTINUE", do exactly that. Per phase: plan, build, self-review,
validate.sh, commit, CI, fix, QA, report. Before you run out of budget,
write the exact next steps into ROADMAP.md.
Never leave placeholders, TODO stubs, dummy data or fake features. If
something can't hit its target on phones, ship a real lower tier and
record it in LIMITS.md. Never leave the build broken: fix forward or
revert.

BEGIN NOW: write STUDIO_BIBLE, ART_BIBLE and ROADMAP, then do Phase 0.

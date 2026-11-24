# ART BIBLE — Coastline: Vicio Bay

## 1. Visual Thesis (2026 Photoreal Coastal Megacity)
**Modern, sleek, high-contrast Florida megacity in 2026.** Not retro, not 1980s synthwave. Think sunlit travertine & low-iron architectural glass, brushed aluminum, wet dark asphalt reflecting warm amber/cyan LED signage, teal coastal shallows meeting deep Atlantic cobalt, and crisp golden-hour rim light against cool teal shadows.

## 2. Color & Lighting Palettes

### Time-of-Day Key Light & Sky Ratios
| Phase | Sun Angle | Key Color (sRGB) | Shadow/Sky Fill | Fog / Aerial | Mood |
|---|---|---|---|---|---|
| Dawn (05:30-07:30) | 4-15° | `#FFB37A` (Warm Peach) | `#2B4C65` (Cool Slate) | `#7FA3B8` | Mist over canals, warm glass edges |
| Midday (10:00-15:30) | 55-75° | `#FFF9F0` (Crisp Sun) | `#4B7FA6` (Tropical Azure) | `#A7CCE0` | High clarity, harsh speculars, bright palms |
| Golden Hour (17:30-19:15) | 3-14° | `#FF9642` (Rich Amber) | `#1B4A5E` (Teal Shadow) | `#D98D68` | Signature look: warm key vs cool teal bounce |
| Blue Hour (19:15-20:15) | -4-2° | `#3E6B89` (Sky Bounce) | `#0D1C2E` (Deep Marine) | `#1C344D` | Architectural LEDs ignite against cobalt sky |
| Night (20:15-05:30) | Moon | `#7A9BC4` (Moonlight) | `#060C14` (Midnight) | `#0B1726` | Crisp white 5000K streetlights, cyan/amber accents |

### District Material & Accent Palettes
- **Bayfront (Financial Core)**: Low-iron curtain-wall glass (`#8BB5C9`, roughness `0.06`, metallic `0.15`), anodized champagne aluminum (`#B8A99A`), travertine plazas (`#DDD4C6`), crisp white LED crown strips (`#F4FAFF`).
- **Palm Row (Luxury Waterfront)**: Whitewashed stucco (`#F2EFE9`), teak decking (`#7A5438`), turquoise infinity pools (`#12B8C4`), warm bollard lighting (`#FFC978`), royal palms.
- **Mural District (Art & Nightlife)**: Raw poured concrete (`#828588`), painted brick murals (saturated coral `#FF5A52`, electric cyan `#00D4FF`, marigold `#FFB800`, deep violet `#6B2CF5`), wet polished concrete walkways.
- **Marlin Point (Island Mansions)**: Limestone cladding (`#E5DEC9`), bronze louvers (`#594A3C`), manicured turf (`#2F6B36`), yacht marinas.
- **Port Merrick (Industrial Container Port)**: Weathered corten steel (`#8C3B2B`), maritime blue (`#1F4E78`), safety yellow (`#E6A817`), oil-stained concrete (`#4A4D50`), sodium/LED floodlight towers.
- **Sawgrass Flats (Wetlands)**: Tannic dark water (`#1E2B22`), sawgrass olive (`#6A7542`), weathered cypress wood (`#5C5248`), humid golden haze.

## 3. PBR Material Standards
- **Calibrated Albedo**: Never pure `#000000` (min 0.025 linear / `#2A2A2A` sRGB for asphalt/rubber) or pure `#FFFFFF` (max 0.85 linear / `#EAEAEA` sRGB for clean stucco).
- **Asphalt & Roads**: Base albedo `#2B2E33` (dry) -> `#16181C` (wet), roughness `0.78` (dry) -> `0.12` (puddles via wetness mask), normal map + macro variation + tire-rubber darkening in lane centers.
- **Architectural Glass**: `roughness 0.04-0.10`, `metallic 0.1`, high specular (`0.8+`), subtle interior parallax/emissive window grid at night (procedural shader to avoid heavy interior geometry at distance).
- **Automotive Clearcoat**: Multi-layer look — metallic flake base + `clearcoat = 1.0`, `clearcoat_roughness = 0.04-0.08`, anisotropic carbon fiber weave (`roughness 0.25`) for aero splitters/diffusers.
- **Skin & Hair**: Subsurface scattering approximation on Mobile/Forward+, micro-pore normal map, sweat roughness modulation (`0.55` -> `0.22`). Hair uses alpha-to-coverage strand cards with Kajiya-Kay anisotropic highlight.

## 4. Fictional Brand & Signage Guidelines (100% Original IP)
- **Typography**: Clean geometric sans-serif (Inter/Montserrat/Rajdhani equivalents or procedural vector/font assets) for financial towers, sleek condensed grotesk for hypercar badges, bold stencil/spray for Mural District.
- **Fictional Corporations & Makers** (examples, zero real-world IP):
  - **Auto Makers**: *Vessari* (Italian wedge supercars), *Duvallier* (French quad-turbo hypercars), *Kurogane* (Japanese precision coupes), *Bravado-free* original US muscle *Ironworks / Calderon Motors*, *Apex-free* EV maker *Voltaire Dynamics*, *Merrick Heavy* (trucks/commercial).
  - **Tech & Crypto**: *Solis Ledger*, *Bayside Capital*, *Nautilus Cloud*, *Palmetto Bio*.
  - **Consumer / Street**: *Caña Cold Brew*, *TropiCharge EV*, *Vicio Bay Transit (VBT)*, *BayGuard Security*.

## 5. Renderer Parity Rules (`STANDARD` vs `ULTRA`)
- **STANDARD (`mobile` renderer)**: Dynamic directional sun + sky ambient + runtime `ReflectionProbe` boxes per district, baked vertex AO, custom sky shader, wet-surface roughness modulation, FSR 1.0 upscaling, ACES/AgX filmic tonemapping, subtle bloom. Target: `<1,500` draw calls, `<2M` triangles, 30–60 fps on mid-range Android arm64.
- **ULTRA (`forward_plus` renderer)**: Adds SDFGI (optional per Ultra High preset), SSR on wet asphalt/water, SSAO/SSIL, volumetric fog/god-ray scattering, FSR 2.2. Target: 60 fps on flagship Android arm64.

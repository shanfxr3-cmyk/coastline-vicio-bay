# LIMITS — Coastline: Vicio Bay

Document real-world platform, toolchain, hardware, and Godot 4 renderer constraints here. Never fake a feature; ship a verified lower tier and log why here.

| ID | Area | Constraint / Decision | Impact & Mitigation |
|---|---|---|---|
| `L-001` | Codespace GPU | No hardware GPU in Codespace container; renders via Mesa Lavapipe software Vulkan (`VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`) + `xvfb` | Local screenshots run slower than real phone hardware and reflect software Vulkan behavior; final FPS/thermal tuning must be validated on physical Android arm64 devices. |

# LIMITS — Coastline: Vicio Bay

Document real-world platform, toolchain, hardware, and Godot 4 renderer constraints here. Never fake a feature; ship a verified lower tier and log why here.

| ID | Area | Constraint / Decision | Impact & Mitigation |
|---|---|---|---|
| `L-001` | Codespace GPU | No hardware GPU in Codespace container; renders via Mesa Lavapipe software Vulkan (`VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json`) + `xvfb` | Local screenshots run slower than real phone hardware and reflect software Vulkan behavior; final FPS/thermal tuning must be validated on physical Android arm64 devices. |
| `L-002` | Mobile Renderer 3D Scaling | Godot 4.7.2 `mobile` renderer supports `SCALING_3D_MODE_BILINEAR` for `scaling_3d_scale < 1.0`, while `SCALING_3D_MODE_FSR` / `FSR2` require `forward_plus`. | `STANDARD` (`mobile`) build uses bilinear render scaling with `scaling_3d_scale` (`0.67` Low / `0.85` Medium / `1.0` High); `ULTRA` (`forward_plus`) uses `FSR2`. |
| `L-003` | Gradle JVM Memory | Godot 4.7.2 default `gradle.properties` requests `-Xmx4536m`, which triggers OOM killer in 7.8 GiB containers without swap. | `tools/build_android.sh` patches `android/build/gradle.properties` to `-Xmx2048m -XX:MaxMetaspaceSize=512m` and `org.gradle.daemon=false`. |
| `L-004` | Release Signing Secrets | `godot --export-release` fails without a release keystore (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`). | CI and `tools/build_android.sh` automatically use release signing when those GitHub Secrets are configured and fall back to debug-signed APKs/AAB otherwise. |

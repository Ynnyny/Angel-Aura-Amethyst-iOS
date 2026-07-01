# MobileGlues Settings Reference

## Overview

This document documents all configurable settings for MobileGlues (MG) — the OpenGL compatibility layer used by Amethyst to translate desktop OpenGL calls to Apple Metal via OpenGL ES.

MobileGlues reads its configuration from a JSON file at `<mg_directory>/config.json`. On iOS, this directory is set to `$POJAV_HOME/mg_config/` via the `MG_DIR_PATH` environment variable.

---

## All Configurable Settings

### 1. FSR1 Upscaling (`fsr1Setting`)

Built-in FidelityFX Super Resolution 1.0 upscaling. Renders at a lower resolution internally and upscales to native resolution.

| Value (Int) | Preset          | Scale Factor | Description |
|-------------|-----------------|--------------|-------------|
| 0           | Disabled        | N/A          | FSR off, native resolution |
| 1           | Ultra Quality   | 1.3x         | Highest quality, least performance gain |
| 2           | Quality         | 1.5x         | Good balance |
| 3           | Balanced        | 1.7x         | Balanced quality/performance |
| 4           | Performance     | 2.0x         | Best performance, lowest quality |

**Android JSON key:** `fsr1Setting`  
**iOS Pref key:** `mobileglues.mg_fsr1`  
**Default (iOS):** `0` (Disabled)

---

### 2. ANGLE Backend (`enableANGLE`)

Configure how ANGLE (Almost Native Graphics Layer Engine) is used as the OpenGL ES driver backend.

| Value (Int) | Mode              | Description |
|-------------|-------------------|-------------|
| 0           | DisableIfPossible | Disable ANGLE if native GLES is available |
| 1           | EnableIfPossible  | Try to use ANGLE if supported by GPU |
| 2           | ForceDisable      | Never use ANGLE |
| 3           | ForceEnable       | Always use ANGLE |

**Note:** On iOS, ANGLE is always disabled (Metal is the native backend). This setting may be useful for future builds with ANGLE support.

**Android JSON key:** `enableANGLE`  
**iOS Pref key:** `mobileglues.mg_enable_angle`  
**Default (iOS):** `0` (DisableIfPossible)

---

### 3. No Error Context (`enableNoError`)

Controls `GL_KHR_no_error` behavior. When enabled, GL error checking is skipped for performance.

| Value (Int) | Mode     | Description |
|-------------|----------|-------------|
| 0           | Auto     | Let the driver decide |
| 1           | Disable  | Disable no-error mode |
| 2           | Level 1  | Partial error ignoring |
| 3           | Level 2  | Full error ignoring |

**Android JSON key:** `enableNoError`  
**iOS Pref key:** `mobileglues.mg_no_error`  
**Default (iOS):** `1` (Disable / Partial via `ignore_error`)

---

### 4. Compute Shader Extension (`enableExtComputeShader`)

Expose the `GL_ARB_compute_shader` extension to the application. Required by some modern mods (e.g., Sodium 0.6+, Iris shader packs).

| Value (Bool) | Description |
|--------------|-------------|
| false        | Do not expose compute shader extension |
| true         | Expose compute shader extension |

**Android JSON key:** `enableExtComputeShader`  
**iOS Pref key:** `mobileglues.mg_enable_ext_compute_shader`  
**Default (iOS):** `false`

---

### 5. Timer Query Extension (`enableExtTimerQuery`)

Expose `GL_ARB_timer_query` or `GL_EXT_timer_query` extensions. Used for GPU performance queries (e.g., F3 debug screen).

| Value (Bool) | Description |
|--------------|-------------|
| false        | Do not expose timer query extension |
| true         | Expose timer query extension |

**Android JSON key:** `enableExtTimerQuery`  
**iOS Pref key:** `mobileglues.mg_enable_ext_timer_query`  
**Default (iOS):** `false`

---

### 6. Direct State Access (`enableExtDirectStateAccess`)

Expose `GL_ARB_direct_state_access` / `GL_EXT_direct_state_access` extensions.

| Value (Bool) | Description |
|--------------|-------------|
| false        | Do not expose DSA extension |
| true         | Expose DSA extension |

**Android JSON key:** `enableExtDirectStateAccess`  
**iOS Pref key:** `mobileglues.mg_enable_ext_dsa`  
**Default (iOS):** `true`

---

### 7. Custom GL Version (`customGLVersion`)

Override the reported OpenGL version string. This tricks the game into thinking a different GL version is available.

| Value (Int) | GL Version | Notes |
|-------------|------------|-------|
| 0           | Default    | Let MG decide (4.0 on iOS) |
| 32          | 3.2        | |
| 33          | 3.3        | |
| 40          | 4.0        | Default |
| 41          | 4.1        | |
| 42          | 4.2        | |
| 43          | 4.3        | |
| 44          | 4.4        | |
| 45          | 4.5        | |
| 46          | 4.6        | |

**Android JSON key:** `customGLVersion`  
**iOS Pref key:** `mobileglues.mg_custom_gl_version`  
**Default (iOS):** `0` (Default = 4.0)

---

### 8. Multi-draw Mode (`multidrawMode`)

How MG emulates desktop GL multi-draw calls.

| Value (Int) | Mode                | Description |
|-------------|---------------------|-------------|
| 0           | Auto                | MG automatically picks the best mode |
| 1           | PreferIndirect      | `glDrawElementsIndirect` |
| 2           | PreferBaseVertex    | `glDrawElementsBaseVertex` (CPU unroll) |
| 3           | PreferMultidrawIndirect | `glMultiDrawElementsIndirect` |
| 4           | DrawElements        | `glDrawElements` with per-draw CPU rebase |
| 5           | Compute             | `glDrawElements` with compute-shader rebase |

**Android JSON key:** `multidrawMode`  
**iOS Pref key:** `mobileglues.mg_multidraw_mode`  
**Default (iOS):** `4` (DrawElements)

---

### 9. ANGLE Depth Clear Fix (`angleDepthClearFixMode`)

Workaround for ANGLE depth buffer clearing issues.

| Value (Int) | Mode     | Description |
|-------------|----------|-------------|
| 0           | Disabled | No fix applied |
| 1           | Mode 1   | Fix method 1 |
| 2           | Mode 2   | Fix method 2 |

**Note:** Only relevant when ANGLE is enabled.

**Android JSON key:** `angleDepthClearFixMode`  
**iOS Pref key:** `mobileglues.mg_angle_depth_clear_fix`  
**Default (iOS):** `0` (Disabled)

---

### 10. Hide MG Environment Level (`hideMGEnvLevel`)

Hide MobileGlues identifiers from the game application. Useful for bypassing anti-cheat or mod detection.

| Value (Int) | Level  | Description |
|-------------|--------|-------------|
| 0           | Disabled | MG identifiers visible |
| 1           | Level 1 | Randomize GL version/renderer strings, hide MG extensions |

**Android JSON key:** `hideMGEnvLevel`  
**iOS Pref key:** `mobileglues.mg_hide_mg`  
**Default (iOS):** `0` (Disabled)

---

### 11. GLSL Cache Size (`maxGlslCacheSize`)

Maximum size of the on-disk GLSL shader cache. Larger cache = faster shader reloads but more disk space.

| Value (Int) | Unit  | Description |
|-------------|-------|-------------|
| 0           | MB    | Cache disabled |
| 1–999       | MB    | Maximum cache size |

**Android JSON key:** `maxGlslCacheSize`  
**iOS Pref key:** `mobileglues.mg_glsl_cache_size`  
**Default (iOS):** `30` MB

---

## iOS Implementation Details

### Preference Storage

All MG settings are stored in the standard `launcher_preferences_v2.plist` under the `mobileglues` section:

```xml
<key>mobileglues</key>
<dict>
    <key>mg_fsr1</key>
    <integer>0</integer>
    <key>mg_enable_angle</key>
    <integer>0</integer>
    <key>mg_custom_gl_version</key>
    <string>0</string>
    <key>mg_no_error</key>
    <string>1</string>
    <key>mg_enable_ext_compute_shader</key>
    <false/>
    <key>mg_enable_ext_timer_query</key>
    <false/>
    <key>mg_enable_ext_dsa</key>
    <true/>
    <key>mg_multidraw_mode</key>
    <string>4</string>
    <key>mg_angle_depth_clear_fix</key>
    <string>0</string>
    <key>mg_hide_mg</key>
    <false/>
    <key>mg_glsl_cache_size</key>
    <integer>30</integer>
</dict>
```

### Config File Generation

Before MobileGlues initializes (in `egl_bridge.m:pojavInitOpenGL`), the launcher writes a `config.json` to `$POJAV_HOME/mg_config/` and sets `MG_DIR_PATH` to this directory. The generated JSON:

```json
{
    "fsr1Setting": 0,
    "enableANGLE": 0,
    "enableNoError": 1,
    "enableExtComputeShader": 0,
    "enableExtTimerQuery": 0,
    "enableExtDirectStateAccess": 1,
    "customGLVersion": 0,
    "multidrawMode": 4,
    "angleDepthClearFixMode": 0,
    "hideMGEnvLevel": 0,
    "maxGlslCacheSize": 30
}
```

### Initialization Flow

1. App starts → user prefs loaded from `launcher_preferences_v2.plist`
2. User taps "Play" → Java VM starts
3. `pojavCreateContext()` called
4. `pojavInitOpenGL()` called:
   - Sets `MG_DIR_PATH` to `$POJAV_HOME/mg_config/`
   - Writes `config.json` from current prefs (via `MobileGluesConfig.m`)
   - Calls `dlopen("libmobileglues.dylib")`
5. MG static initializer runs → `proc_init()`:
   - `init_config()` → reads `config.json`
   - `init_settings()` → parses and applies settings
6. Minecraft renders with configured settings

### Source Files

| File | Purpose |
|------|---------|
| `Natives/MobileGluesConfig.h` | Helper function declarations |
| `Natives/MobileGluesConfig.m` | Config file writer implementation |
| `Natives/egl_bridge.m` | Integration point (writes config before MG loads) |
| `Natives/PLPreferences.m` | Default MG preference values |
| `Natives/LauncherPreferencesViewController.m` | UI for MG settings |
| `Natives/external/MobileGlues/MobileGlues-cpp/config/settings.cpp` | MG side: reads config.json on iOS |

---

## Comparison: Android vs iOS

| Feature | Android (default) | iOS (default) | iOS User-Configurable |
|---------|-------------------|---------------|----------------------|
| FSR1 Upscaling | Disabled | Disabled | Yes |
| ANGLE Backend | DisableIfPossible | Disabled (Metal native) | Yes |
| No Error | Auto | Disable (Partial) | Yes |
| Compute Shader | Disabled | Disabled | Yes |
| Timer Query | Disabled | Disabled | Yes |
| Direct State Access | Disabled | Enabled | Yes |
| Custom GL Version | 40 (4.0) | 0 (Default=4.0) | Yes |
| Multi-draw Mode | Auto | DrawElements | Yes |
| ANGLE Depth Fix | Disabled | Disabled | Yes |
| Hide MG | Disabled | Disabled | Yes |
| GLSL Cache | 0 (Disabled) | 30 MB | Yes |

---

## References

- [MobileGlues Source Code](https://github.com/MobileGL-Dev/MobileGlues)
- [MobileGlues Releases](https://github.com/MobileGL-Dev/MobileGlues-release/releases)
- [MobileGlues Plugin (Android)](https://github.com/MobileGL-Dev/MobileGlues-plugin)
- [Amethyst Project](https://github.com/angelauramc/Amethyst-iOS)

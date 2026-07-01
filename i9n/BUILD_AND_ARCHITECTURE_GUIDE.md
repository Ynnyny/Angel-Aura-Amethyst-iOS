# Angel Aura Amethyst - Build & Architecture Guide

## Overview

Angel Aura Amethyst (based on PojavLauncher) is a Minecraft: Java Edition launcher for iOS/iPadOS. It runs an embedded OpenJDK JVM on iOS and launches Minecraft using a custom LWJGL backend, Caciocavallo AWT, and multiple OpenGL translation layers (GL4ES, MobileGlues, ANGLE/Metal, Zink/Vulkan).

- **Bundle ID:** `org.angelauramc.amethyst`
- **Min iOS:** 14.0
- **Current Version:** 1.0
- **License:** GPL-3.0
- **Organization:** [AngelAuraMC](https://github.com/AngelAuraMC)
- **Repository:** [Amethyst-iOS](https://github.com/AngelAuraMC/Amethyst-iOS)

---

## Project Structure

```
Angel-Aura-Amethyst-iOS--main/
├── Amethyst.xcodeproj/          # Xcode project (legacy, uses PBXLegacyTarget → gmake)
├── Makefile                     # MAIN BUILD SYSTEM (434 lines)
├── Natives/                     # iOS native code (Objective-C + CMake)
│   ├── CMakeLists.txt           # CMake build for ObjC executable + shared libs
│   ├── Info.plist               # App Info.plist
│   ├── main.m                   # Entry point
│   ├── JavaLauncher.m           # JVM launch logic
│   ├── SurfaceViewController.m  # Game surface (Metal/GL view)
│   ├── entitlements/            # Authenticator files
│   ├── input/                   # Controller, Gyro, Keyboard input
│   ├── customcontrols/          # On-screen touch controls
│   ├── installer/               # Forge/Fabric/Modpack installers
│   ├── ctxbridges/              # GL/OSMesa renderer bridges
│   ├── external/                # Git submodules
│   ├── resources/               # Bundled resources (localizations, Frameworks, etc.)
│   └── build/                   # CMake build output
├── JavaApp/                     # Java layer (Minecraft launcher core)
│   ├── Makefile                 # Java build file
│   ├── src/                     # Source code (launcher, lwjgl, patchjna)
│   └── libs/                    # Prebuilt Java libs (caciocavallo, lwjgl jars)
├── artifacts/                   # Build output directory (Payload, ipa, java_runtimes)
├── depends/                     # Downloaded Java runtimes (JRE 8, 17, 21)
├── i9n/                         # Documentation directory
│   ├── MobileGlues_Settings_Reference.md
│   └── BUILD_AND_ARCHITECTURE_GUIDE.md (this file)
├── entitlements.trollstore.xml  # TrollStore entitlements (no-sandbox, JIT, etc.)
└── entitlements.sideload.xml    # Sideload entitlements (sandboxed)
```

---

## Build System

### Requirements

- macOS with Xcode installed (iPhoneOS SDK, minimum iOS 14.0)
- cmake >= 3.6
- JDK 8 (for compiling Java sources with private API access)
- ldid (for pseudo-signing without Apple Developer account)
- wget (for downloading JRE runtimes)
- Git submodules initialized

### Quick Build

```bash
# Initialize submodules
git submodule update --init --recursive

# Build everything for TrollStore (unsigned .tipa)
make TROLLSTORE_JIT_ENT=1 RELEASE=1

# Or build for sideloading
make RELEASE=1
```

### Manual Build Steps (if `assets` target fails due to actool)

```bash
# 1. Build native + java + jre
make native java jre TROLLSTORE_JIT_ENT=1 RELEASE=1

# 2. Manually create payload
SOURCE="Natives/build"
WORKINGDIR="$SOURCE"
OUTPUTDIR="artifacts"
SOURCEDIR="$(pwd)"

rm -rf "$WORKINGDIR/AngelAuraAmethyst.app/libs" && mkdir -p "$WORKINGDIR/AngelAuraAmethyst.app/libs"
rm -rf "$WORKINGDIR/AngelAuraAmethyst.app/libs_caciocavallo" && mkdir -p "$WORKINGDIR/AngelAuraAmethyst.app/libs_caciocavallo"
rm -rf "$WORKINGDIR/AngelAuraAmethyst.app/libs_caciocavallo17" && mkdir -p "$WORKINGDIR/AngelAuraAmethyst.app/libs_caciocavallo17"
cp -R "$SOURCEDIR/Natives/resources/"* "$WORKINGDIR/AngelAuraAmethyst.app/"
cp "$WORKINGDIR/"*.dylib "$WORKINGDIR/AngelAuraAmethyst.app/Frameworks/"
cp -R "$SOURCEDIR/JavaApp/libs/others/"* "$WORKINGDIR/AngelAuraAmethyst.app/libs/"
cp "$SOURCEDIR/JavaApp/build/"*.jar "$WORKINGDIR/AngelAuraAmethyst.app/libs/"
cp -R "$SOURCEDIR/JavaApp/libs/caciocavallo/"* "$WORKINGDIR/AngelAuraAmethyst.app/libs_caciocavallo/"
cp -R "$SOURCEDIR/JavaApp/libs/caciocavallo17/"* "$WORKINGDIR/AngelAuraAmethyst.app/libs_caciocavallo17/"
rm -rf "$OUTPUTDIR/Payload" && mkdir -p "$OUTPUTDIR/Payload"
cp -R "$WORKINGDIR/AngelAuraAmethyst.app" "$OUTPUTDIR/Payload/"
cp -R "$OUTPUTDIR/java_runtimes" "$OUTPUTDIR/Payload/AngelAuraAmethyst.app/"
ldid -S "$OUTPUTDIR/Payload/AngelAuraAmethyst.app/"
ldid -S"$SOURCEDIR/entitlements.trollstore.xml" "$OUTPUTDIR/Payload/AngelAuraAmethyst.app/AngelAuraAmethyst"
chmod -R 755 "$OUTPUTDIR/Payload"

# 3. Package into .tipa
cd artifacts
zip --symlinks -r org.angelauramc.amethyst-1.0-ios-trollstore.tipa Payload
```

### Build Targets

| Target | Description |
|--------|-------------|
| `make all` | Full build (clean → native → java → jre → assets → payload → package → dsym) |
| `make native` | Builds ObjC code via CMake (AngelAuraAmethyst executable + dylibs) |
| `make java` | Compiles Java sources into launcher.jar, lwjgl.jar, patchjna_agent.jar |
| `make jre` | Downloads & extracts JRE 8/17/21, copies awt_xawt dylib |
| `make dep_mg` | Builds MobileGlues from submodule |
| `make assets` | Compiles Assets.xcassets (requires actool, can fail without simulator runtime) |
| `make payload` | Assembles the .app bundle |
| `make package` | Packages into .ipa/.tipa and optionally codesigns |
| `make dsym` | Generates debug symbol files |
| `make clean` | Removes build directories |

### Key Build Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TROLLSTORE_JIT_ENT` | unset | Set to `1` to use TrollStore entitlements (no-sandbox, auto-JIT) |
| `RELEASE` | 0 | Set to `1` for Release build (vs Debug) |
| `PLATFORM` | 2 (iOS) | 2=iOS, 3=tvOS, 6=maccatalyst, 7=iossimulator, etc. |
| `SLIMMED` | 0 | Set to `1` to create a slimmed IPA (without JREs) |
| `SLIMMED_ONLY` | 0 | Set to `1` to build only the slimmed version |
| `TEAMID` / `SIGNING_TEAMID` / `PROVISIONING` | -1 | For Apple Developer codesigning (skip if -1) |

### Makefile Function Reference

- `METHOD_DEPCHECK`: Checks if a tool/command is available
- `METHOD_INFOPLIST`: Modifies Info.plist values
- `METHOD_DIRCHECK`: Creates or clears a directory
- `METHOD_CHANGE_PLAT`: Changes Mach-O platform (for cross-platform builds)
- `METHOD_PACKAGE`: Creates .ipa or .tipa zip file
- `METHOD_JAVA_UNPACK`: Downloads and extracts JRE archives
- `METHOD_CODESIGN`: Codesigns Mach-O files with Apple Developer cert
- `METHOD_MACHO`: Iterates over Mach-O files in a directory

---

## Architecture

### Two-Tier Architecture

```
┌─────────────────────────────────────────────────┐
│  iOS Native Layer (Objective-C)                 │
│  main.m → AppDelegate → SceneDelegate           │
│       ↓                                         │
│  LauncherSplitViewController                    │
│   ├── LauncherMenuViewController (sidebar)      │
│   └── LauncherNavigationController              │
│       └── [News, Profiles, Preferences, ...]    │
│                                                 │
│  "Play" → SurfaceViewController                 │
│   ├── GameSurfaceView (CAMetalLayer/CALayer)    │
│   ├── ControlLayout (custom controls overlay)   │
│   ├── input_bridge_v3 (touch → GLFW events)     │
│   └── JavaLauncher (JLI_Launch → JVM start)     │
└─────────────┬───────────────────────────────────┘
              │ JNI bridge
              ▼
┌─────────────────────────────────────────────────┐
│  Java Layer (OpenJDK 8/17/21)                   │
│  PojavLauncher.main()                           │
│   ├── Launch Minecraft JAR                      │
│   ├── PojavClassLoader (custom class loader)    │
│   └── UIKit.java (JNI ↔ ObjC bridge)            │
│                                                 │
│  Minecraft: Java Edition                        │
│   └── LWJGL3 (custom GLFW implementation)       │
│       └── CallbackBridge ←→ egl_bridge          │
│           → GLFW events → ObjC input_bridge     │
└─────────────────────────────────────────────────┘
```

### Key Native Files

| File | Purpose |
|------|---------|
| `main.m` | Entry point, JIT enablement, home dir setup, stdio redirect |
| `JavaLauncher.m` | Dynamic loading of libjli.dylib, JVM argument construction, JLI_Launch() |
| `SurfaceViewController.m` | Main game surface (Metal/GL), touch input, lifecycle |
| `SurfaceViewController+ExternalDisplay.m` | External display (AirPlay) support |
| `egl_bridge.m` | EGL context creation, renderer selection (GL4ES/MG/ANGLE/OSMesa) |
| `input_bridge_v3.m` | Touch → GLFW event translation |
| `UIKit+hook.m` | Runtime swizzling of UIKit (tvOS compat, UI customization) |
| `main_hook.m` | C function hooking via fishhook (dlopen, abort, exit, open) |
| `dyld_bypass_validation.m` | Bypasses dyld library validation for unsigned dylibs |
| `dyld_patch_platform.m` | Patches Mach-O platform flags |
| `LauncherPreferences.m` | Preference system (plist-based) |
| `PLPreferences.m` | Preferences storage/retrieval |
| `PLProfiles.m` | Minecraft profiles management |
| `MobileGluesConfig.m` | Writes MobileGlues config.json before initialization |
| `ios_uikit_bridge.m` | UIKit ↔ Java bridge methods |
| `GameSurfaceView.m` | Metal-backed UIView for rendering |

### Core Native Source Files

- `AppDelegate.m` - UIApplicationDelegate, scene session management
- `SceneDelegate.m` - UISceneDelegate, window setup
- `SceneExternalDelegate.m` - External display scene delegate
- `LauncherSplitViewController.m` - Main split view controller (sidebar + detail)
- `LauncherMenuViewController.m` - Sidebar menu (news, profiles, settings, etc.)
- `LauncherNavigationController.m` - Detail navigation controller
- `LauncherNewsViewController.m` - WebKit-based news view
- `LauncherProfilesViewController.m` - Minecraft version/profile list
- `LauncherProfileEditorViewController.m` - Profile editing
- `LauncherPreferencesViewController.m` - Settings view
- `LauncherPreferences.h/.m` - Preferences model
- `LauncherPrefContCfgViewController.m` - Controls configuration
- `LauncherPrefGameDirViewController.m` - Game directory management
- `LauncherPrefManageJREViewController.m` - Java runtime selection

### Custom Controls System

- `ControlLayout.h/.m` - Layout container for controls
- `ControlButton.h/.m` - On-screen button
- `ControlJoystick.h/.m` - On-screen joystick
- `ControlDrawer.h/.m` - Drawer (expandable control group)
- `ControlSubButton.h/.m` - Sub-button within drawer
- `CustomControlsUtils.h/.m` - Utility functions
- `NSPredicateUtilitiesExternal.h/.m` - Predicate-based control filtering
- `CustomControlsViewController.h/.m` - Control editor UI
- `CustomControlsViewController+UndoManager.m` - Undo support

### Input System

- `input_bridge_v3.m` - Touch/Mouse → GLFW event translation (613 lines)
- `ControllerInput.h/.m` - MFi/game controller support via GameController framework
- `GyroInput.h/.m` - Gyroscope/motion-based input
- `KeyboardInput.h/.m` - Hardware keyboard support

### Renderer System

Rendering backend selected via `POJAV_RENDERER` env var (set in JavaLauncher.m):

| Renderer | Library | Description | Best For |
|----------|---------|-------------|----------|
| GL4ES | `libgl4es_114.dylib` | OpenGL 1.x/2.x → GLES | Older MC versions (pre-1.17) |
| MobileGlues | `libmobileglues.dylib` | Modern OpenGL → GLES/Metal | MC 1.17+, performance |
| ANGLE | `libtinygl4angle.dylib` | OpenGL ES → Metal (via ANGLE) | MC 1.17+ compatibility |
| OSMesa/Zink | `libOSMesa.8.dylib` | Software rasterizer | Debug/testing |

### JIT Enablement

The app supports multiple JIT enablement methods:
1. **TrollStore** (auto) - No-sandbox entitlement enables `PT_TRACE_ME` workaround
2. **AltStore/SideStore** - Requires AltServer/SideStore on local network
3. **StikDebug** - Uses `UniversalJIT26.js` JavaScript exploit
4. **Jailbreak** - Automatically detected via substrate/pspawn_payload/platform-binary checks

---

## Java Layer

### Source: `JavaApp/src/`

| Package | Key Files | Purpose |
|---------|-----------|---------|
| `launcher` | `PojavLauncher.java` | Java entry point, initializes Caciocavallo, launches MC |
| `launcher` | `Tools.java` | Classpath generation, version argument resolution |
| `launcher` | `PojavClassLoader.java` | Custom URLClassLoader for loading MC classes |
| `launcher/uikit` | `UIKit.java` | JNI bridge to native ObjC |
| `launcher/utils` | `JSONUtils.java`, `MCOptionUtils.java` | JSON parsing, MC options |
| `launcher/value` | Multiple files | Data models (versions, libraries, accounts, profiles) |
| `lwjgl` | `GLFW.java`, `CallbackBridge.java`, etc. | Custom GLFW implementation for iOS |
| `patchjna` | `PatchJNAAgent.java` | JNA platform patching |

---

## Authentication

- `BaseAuthenticator.h/.m` - Abstract base class
- `LocalAuthenticator.m` - Offline/demo mode
- `MicrosoftAuthenticator.m` - Microsoft OAuth 2.0 flow with refresh tokens
- `MinecraftAccountJNI.m` - JNI bridge between Java accounts and native storage
- `AccountListViewController.m` - Account management UI

---

## Installers

- `FabricInstallViewController.m` / `FabricUtils.m` - Fabric/Quilt mod loader installer
- `ForgeInstallViewController.m` - Forge mod loader installer
- `ModpackInstallViewController.m` - Modpack installer UI
- `CurseForgeAPI.m` - CurseForge API client
- `ModrinthAPI.m` - Modrinth API client
- `ModpackAPI.m` / `ModpackUtils.m` - Generic modpack handling

---

## Submodules

| Submodule | Path | Purpose |
|-----------|------|---------|
| [DBNumberedSlider](https://github.com/khanhduytran0/DBNumberedSlider) | `Natives/external/DBNumberedSlider` | Numbered slider UI control |
| [fishhook](https://github.com/khanhduytran0/fishhook) | `Natives/external/fishhook` (branch: `jev/main`) | C function hooking |
| [AFNetworking](https://github.com/AFNetworking/AFNetworking) | `Natives/external/AFNetworking` | HTTP networking |
| [MobileGlues](https://github.com/MobileGL-Dev/MobileGlues) | `Natives/external/MobileGlues` (branch: `main`) | OpenGL compatibility layer |

### Embedded Dependencies (not submodules)

| Dependency | Path | Purpose |
|------------|------|---------|
| AltKit | `Natives/external/AltKit` | AltStore communication |
| Apple | `Natives/external/Apple` | Apple private headers |
| ballpa1n | `Natives/external/ballpa1n` | JIT enablement library |
| gl4es | `Natives/external/gl4es` | OpenGL 1.x/2.x wrapper |
| lzma | `Natives/external/lzma` | LZMA compression |
| mach | `Natives/external/mach` | Mach exception handling |
| mesa | `Natives/external/mesa` | Mesa GL headers |
| NRFileManager | `Natives/external/NRFileManager` | File manager utilities |
| UnzipKit | `Natives/external/UnzipKit` | ZIP archive handling |

### Prebuilt Frameworks (in `Natives/resources/Frameworks/`)

These are pre-compiled binary dylibs/frameworks that ship with the source:

- `AltKit.framework`, `CAltKit.framework` - AltStore communication
- `UnzipKit.framework` - ZIP handling
- `libEGL.framework`, `libGLESv2.framework` - ANGLE/Metal translation
- `libgl4es_114.dylib` - GL4ES OpenGL 1.x/2.x
- `libmobileglues.dylib` - MobileGlues
- `libtinygl4angle.dylib` - ANGLE wrapper for MC 1.17+
- `libOSMesa.8.dylib` - Software rasterizer
- `libMoltenVK.dylib` - Vulkan → Metal
- `libopenal.dylib` - OpenAL audio
- `libfreetype.dylib` - Font rendering
- `libshaderc.dylib` - Shader compilation
- `liblwjgl*.dylib` (7 libs) - LWJGL native libraries
- `libglapi.0.dylib` - GL API dispatch
- `libvirgl_test_server.dylib` - VirGL test server

---

## Entitlements

### TrollStore (`entitlements.trollstore.xml`)
- `com.apple.private.security.no-sandbox` → Disables sandbox, enables auto-JIT
- `com.apple.developer.kernel.extended-virtual-addressing` → 64-bit addressing
- `com.apple.developer.kernel.increased-memory-limit` → More memory
- `com.apple.private.memorystatus` → Jetsam control
- `platform-application` → Platform binary flag
- Security storage exceptions for AppDataContainers, MobileDocuments
- IOKit user client classes for Metal/GPU access
- Mach lookup global names for NSURLSession

### Sideload (`entitlements.sideload.xml`)
- `com.apple.private.security.container-required` → Sandboxed container
- No auto-JIT (requires external JIT enablement)
- `jb.pmap_cs_custom_trust` → Custom trust for TrollStore detection

---

## Troubleshooting

### `assets` target fails with "No simulator runtime available"
The `actool` command requires a simulator runtime. Workaround:
```bash
# Just skip the assets target and manually copy precompiled resources
make native java jre TROLLSTORE_JIT_ENT=1 RELEASE=1
# Then manually run the payload commands (see "Manual Build Steps" above)
```

### Git has no commits error
```makefile
fatal: your current branch 'main' does not have any commits yet
```
This is a non-fatal warning. The Makefile uses `git branch --show-current` and `git log` for version info. If the repo has no commits, it defaults to "unknown". To fix:
```bash
git add -A && git commit -m "Initial commit"
```

### Submodules not initialized
```bash
git submodule update --init --recursive
```

### `ldid: command not found`
Install ldid: `brew install ldid`

---

## Build Output

After a successful build, the following files are created in `artifacts/`:

- `Payload/AngelAuraAmethyst.app/` - The .app bundle
- `org.angelauramc.amethyst-1.0-ios-trollstore.tipa` - TrollStore IPA (~136 MB)
- `org.angelauramc.amethyst-1.0-ios.ipa` - Standard IPA (no TrollStore entitlements)
- `java_runtimes.zip` - Zipped JREs for distribution

---

## App Bundle Contents

```
AngelAuraAmethyst.app/
├── AngelAuraAmethyst          # Main executable (arm64 Mach-O)
├── Info.plist                  # App metadata
├── Assets.car                  # Compiled asset catalog
├── Frameworks/                 # Dynamic libraries & frameworks
│   ├── libmobileglues.dylib
│   ├── libgl4es_114.dylib
│   ├── libMoltenVK.dylib
│   ├── libOSMesa.8.dylib
│   ├── liblwjgl*.dylib (7)
│   ├── libEGL.framework/
│   ├── libGLESv2.framework/
│   ├── AltKit.framework/
│   ├── CAltKit.framework/
│   ├── UnzipKit.framework/
│   └── ... (20 dylibs total)
├── libs/                       # Java libraries
│   ├── launcher.jar            # Java launcher core
│   ├── lwjgl.jar               # LWJGL binding
│   ├── patchjna_agent.jar      # JNA patching agent
│   ├── gson-2.13.1.jar
│   ├── arc_dns_injector.jar
│   └── jsr305.jar
├── libs_caciocavallo/          # Caciocavallo AWT (Java 8)
│   ├── cacio-shared-1.10-SNAPSHOT.jar
│   ├── cacio-androidnw-1.10-SNAPSHOT.jar
│   └── ResConfHack.jar
├── libs_caciocavallo17/        # Caciocavallo AWT (Java 17+)
│   ├── cacio-shared-1.18-SNAPSHOT.jar
│   └── cacio-tta-1.18-SNAPSHOT.jar
├── java_runtimes/              # Embedded JVMs
│   ├── java-8-openjdk/
│   ├── java-17-openjdk/
│   └── java-21-openjdk/
├── *.lproj/                    # Localizations (50+ languages)
├── UniversalJIT26.js           # StikDebug JIT exploit script
├── log4j-rce-patch-*.xml       # Log4j vulnerability patches
├── glfw_keycodes.plist         # Keycode mapping
└── AppIcon*.png                # App icons
```

---

## Important Notes for Developers

1. **Assets target**: The `actool` step often fails on machines without iOS simulator runtimes. The precompiled assets in `Natives/resources/` are sufficient for building.

2. **Java compilation**: Requires JDK 8 specifically (due to private API access with `-XDignore.symbol.file`). The version check in the Makefile strips to 7 chars and expects `1.8.0`.

3. **Slimmed builds**: Setting `SLIMMED=1` creates an IPA without JREs (~40 MB vs ~136 MB). Users download JREs separately on first launch.

4. **Branch/Commit**: The repository currently has no commits. The `terminalis` branch confusion: the Makefile checks `main` but the active branch may be different. This is cosmetic only.

5. **Submodule state**: Some submodules may be checked out at specific pinned commits, not branch heads. Always use `git submodule update --init --recursive`.

6. **ldid signing**: The `ldid -S` command on the .app directory creates a `_CodeSignature/CodeResources` and an embedded.mobileprovision equivalent. The second `ldid -S<entitlements.xml>` on the binary applies the actual entitlements.

7. **Info.plist**: The project stores the real Info.plist at `Natives/Info.plist` (not in the Xcode project root). CMake copies/uses it during the build.

## Summary
Add MobileGlues renderer settings to iOS settings UI and make them effective (like Android).

## Changes
- **PLPreferences.m**: Add 10 MobileGlues default preferences under `@"mobileglues"` section
- **LauncherPreferencesViewController.m**: Add MobileGlues settings section (switches, slider, pickers) after Video section
- **Localizable.strings (en)**: Add section header, footer, titles, details, picker option labels for all MG settings
- **JavaLauncher.m**: Add `init_loadMobileGluesConfig()` that writes `MG_DIR_PATH/config.json` with camelCase keys and sets `MG_DIR_PATH` env var before `dlopen`
- **settings.cpp**: Remove `#if defined(__APPLE__)` guard so iOS reads config.json like Android
- **PLPrefTableViewController.m**: Fix `-[NSNumber isEqualToString:]` crash for picker fields by converting NSNumber to NSString
- **Makefile**: Fix `BRANCH`/`COMMIT` fallback + `dep_mg` source path

## Testing
- Device: iPhone 8 Plus, iOS 16.7.16 (Jailbroken, TrollStore)
- Minecraft: 26.2 Java Edition
- Renderer: MobileGlues (libmobileglues.dylib)
- Build: `.ipa` created successfully (184 MB)
- Settings UI: No crash on tap, all 10 options visible
- Config: Written to `$POJAV_HOME/MG/config.json`, read by MobileGlues at dylib init

## Notes
- All settings that work on Android are now available on iOS
- Settings actually take effect (config.json + MG_DIR_PATH env var)
- No Swift code (pure ObjC project)
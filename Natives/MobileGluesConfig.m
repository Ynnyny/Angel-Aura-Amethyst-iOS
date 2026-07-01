#import "MobileGluesConfig.h"
#import "LauncherPreferences.h"
#import "utils.h"
#import <Foundation/Foundation.h>

NSString* getMobileGluesConfigPath(void) {
    NSString *pojavHome = @(getenv("POJAV_HOME"));
    return [pojavHome stringByAppendingPathComponent:@"mg_config"];
}

void setMobileGluesEnvironment(void) {
    NSString *configPath = getMobileGluesConfigPath();
    setenv("MG_DIR_PATH", configPath.UTF8String, 1);
}

void writeMobileGluesConfig(void) {
    NSString *configPath = getMobileGluesConfigPath();

    NSFileManager *fm = NSFileManager.defaultManager;
    NSError *error = nil;
    [fm createDirectoryAtPath:configPath withIntermediateDirectories:YES
                   attributes:nil error:&error];
    if (error) {
        NSLog(@"[MobileGluesConfig] Failed to create MG config directory: %@", error);
        return;
    }

    setenv("MG_DIR_PATH", configPath.UTF8String, 1);

    NSString *pojavHome = @(getenv("POJAV_HOME"));
    NSString *prefPath = [pojavHome stringByAppendingPathComponent:@"launcher_preferences_v2.plist"];
    NSDictionary *globalPref = [NSDictionary dictionaryWithContentsOfFile:prefPath];
    NSDictionary *mgPrefs = globalPref[@"mobileglues"];
    if (!mgPrefs) {
        NSDebugLog(@"[MobileGluesConfig] No MG prefs found, using defaults");
        mgPrefs = @{};
    }

    // FSR1: stored as NSString int, default "0"
    int fsr1 = [[mgPrefs objectForKey:@"mg_fsr1"] intValue];

    // ANGLE: stored as NSString int, default "0"
    int enableANGLE = [[mgPrefs objectForKey:@"mg_enable_angle"] intValue];

    // No Error: stored as NSString int, default "1"
    int enableNoError = [[mgPrefs objectForKey:@"mg_no_error"] intValue];

    // Bool extensions
    BOOL extComputeShader = [[mgPrefs objectForKey:@"mg_enable_ext_compute_shader"] boolValue];
    BOOL extTimerQuery = [[mgPrefs objectForKey:@"mg_enable_ext_timer_query"] boolValue];
    BOOL extDSA = [[mgPrefs objectForKey:@"mg_enable_ext_dsa"] boolValue];

    // Custom GL version: stored as NSString int, default "0"
    int customGLVersion = [[mgPrefs objectForKey:@"mg_custom_gl_version"] intValue];

    // Multi-draw mode: stored as NSString int, default "4" (DrawElements)
    int multidrawMode = [[mgPrefs objectForKey:@"mg_multidraw_mode"] intValue];

    // ANGLE depth clear fix: stored as NSString int, default "0"
    int angleDepthClearFix = [[mgPrefs objectForKey:@"mg_angle_depth_clear_fix"] intValue];

    // Hide MG level: stored as BOOL (0/1)
    int hideMGLevel = [[mgPrefs objectForKey:@"mg_hide_mg"] boolValue] ? 1 : 0;

    // GLSL cache size: stored as NSNumber (MB), default 30
    int glslCacheSize = [[mgPrefs objectForKey:@"mg_glsl_cache_size"] intValue];

    NSDictionary *configDict = @{
        @"fsr1Setting": @(fsr1),
        @"enableANGLE": @(enableANGLE),
        @"enableNoError": @(enableNoError),
        @"enableExtComputeShader": @(extComputeShader),
        @"enableExtTimerQuery": @(extTimerQuery),
        @"enableExtDirectStateAccess": @(extDSA),
        @"customGLVersion": @(customGLVersion),
        @"multidrawMode": @(multidrawMode),
        @"angleDepthClearFixMode": @(angleDepthClearFix),
        @"hideMGEnvLevel": @(hideMGLevel),
        @"maxGlslCacheSize": @(glslCacheSize)
    };

    NSString *configFilePath = [configPath stringByAppendingPathComponent:@"config.json"];
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:configDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError];
    if (jsonError || !jsonData) {
        NSLog(@"[MobileGluesConfig] Failed to serialize MG config JSON: %@", jsonError);
        return;
    }

    [jsonData writeToFile:configFilePath atomically:YES];

    NSDebugLog(@"[MobileGluesConfig] Wrote MG config to %@: %@",
               configFilePath,
               [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
}

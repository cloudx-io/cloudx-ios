#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <AdSupport/AdSupport.h> // For ASIdentifierManager

static CLXLogger *logger;

@implementation CLXSettings

+ (void)initialize {
    if (self == [CLXSettings class]) {
        logger = [[CLXLogger alloc] initWithCategory:@"CLXSettings"];
    }
}

+ (instancetype)sharedInstance {
    static CLXSettings *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSString *)getIFA {
    NSString *ifa = nil;
    
    // 1. IFA from UserDefaults (can be set by app for testing or specific scenarios)
    ifa = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreIFAConfigKey];
    if (ifa && ifa.length > 0) {
        [logger info:[NSString stringWithFormat:@"🔧 [CLXSettings] Using configured IFA from UserDefaults: %@", ifa]];
        return ifa;
    }

    // 2. Real device IDFA (primary source)
    if ([CLXAdTrackingService isIDFAAccessAllowed]) {
        ifa = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
        [logger info:[NSString stringWithFormat:@"📱 [CLXSettings] *** ACTUAL DEVICE IDFA FROM ASIdentifierManager: %@ ***", ifa ?: @"(nil)"]];
        if (ifa && ifa.length > 0 && ![ifa isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
            [logger info:[NSString stringWithFormat:@"✅ [CLXSettings] Using real device IDFA: %@", ifa]];
            return ifa;
        }
    } else {
        [logger debug:@"📊 [CLXSettings] IDFA access not allowed by ATT status."];
        // Still log what the IDFA would be even if not allowed
        NSString *actualIDFA = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
        [logger info:[NSString stringWithFormat:@"📱 [CLXSettings] *** ACTUAL DEVICE IDFA (ATT not allowed): %@ ***", actualIDFA ?: @"(nil)"]];
    }

    // 3. Fallback placeholder if no real IDFA is available
    [logger error:@"⚠️ [CLXSettings] No real IDFA available or allowed. Using placeholder."];
    return @"00000000-0000-0000-0000-000000000000";
}



#pragma mark - Retry Configuration

- (BOOL)shouldEnableBannerRetries {
    // Default to NO (disabled) for IDFA protection unless explicitly enabled
    NSNumber *setting = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXCoreEnableBannerRetriesKey];
    if (setting == nil) {
        return NO; // Default disabled for protection
    }
    BOOL enabled = [setting boolValue];
    if (!enabled) {
        [logger debug:@"🚫 [CLXSettings] Banner retries disabled via UserDefaults."];
    }
    return enabled;
}

- (BOOL)shouldEnableInterstitialRetries {
    // Default to NO (disabled) for IDFA protection unless explicitly enabled
    NSNumber *setting = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXCoreEnableInterstitialRetriesKey];
    if (setting == nil) {
        return NO; // Default disabled for protection
    }
    BOOL enabled = [setting boolValue];
    if (!enabled) {
        [logger debug:@"🚫 [CLXSettings] Interstitial retries disabled via UserDefaults."];
    }
    return enabled;
}

- (BOOL)shouldEnableRewardedRetries {
    // Default to NO (disabled) for IDFA protection unless explicitly enabled
    NSNumber *setting = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXCoreEnableRewardedRetriesKey];
    if (setting == nil) {
        return NO; // Default disabled for protection
    }
    BOOL enabled = [setting boolValue];
    if (!enabled) {
        [logger debug:@"🚫 [CLXSettings] Rewarded retries disabled via UserDefaults."];
    }
    return enabled;
}

- (BOOL)shouldEnableNativeRetries {
    // Default to NO (disabled) for IDFA protection unless explicitly enabled
    NSNumber *setting = [[NSUserDefaults standardUserDefaults] objectForKey:kCLXCoreEnableNativeRetriesKey];
    if (setting == nil) {
        return NO; // Default disabled for protection
    }
    BOOL enabled = [setting boolValue];
    if (!enabled) {
        [logger debug:@"🚫 [CLXSettings] Native retries disabled via UserDefaults."];
    }
    return enabled;
}

@end

#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXErrorReporter.h>
#import <CloudXCore/CLXPrivacyService.h>
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
    
    // 1. Configured override (for testing scenarios)
    ifa = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreIFAConfigKey];
    if (ifa && ifa.length > 0) {
        [logger info:[NSString stringWithFormat:@"Using configured IFA from UserDefaults: %@", ifa]];
        return ifa;
    }

    // 2. Privacy-aware IDFA retrieval (unified approach)
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    if (!privacyService) {
        [logger error:@"Privacy service not available - returning zero IDFA for safety"];
        return @"00000000-0000-0000-0000-000000000000";
    }
    
    if ([privacyService shouldClearPersonalData]) {
        [logger debug:@"Privacy requires data clearing - returning zero IDFA"];
        // Still log what the actual IDFA would be for debugging
        NSString *actualIDFA = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
        [logger info:[NSString stringWithFormat:@"*** ACTUAL DEVICE IDFA (privacy blocked): %@ ***", actualIDFA ?: @"(nil)"]];
        return @"00000000-0000-0000-0000-000000000000";
    }

    // 3. Real device IDFA (privacy allows and ATT authorized)
    ifa = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
    [logger debug:[NSString stringWithFormat:@"*** ACTUAL DEVICE IDFA FROM ASIdentifierManager: %@ ***", ifa ?: @"(nil)"]];
    if (ifa && ifa.length > 0 && ![ifa isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
        [logger debug:[NSString stringWithFormat:@"Using real device IDFA: %@", ifa]];
        return ifa;
    }

    // 4. Fallback placeholder if no real IDFA is available (log once per session)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [logger info:@"No real IDFA available, using placeholder (ATT not authorized or IDFA unavailable)"];
    });
    return @"00000000-0000-0000-0000-000000000000";
}

@end

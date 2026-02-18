#import "CLXMintegralInitializer.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXBidderConfig.h>
#import <MTGSDK/MTGSDK.h>

// CloudX Channel Code for Mintegral attribution
// This is a unique identifier assigned by Mintegral for CloudX mediation
static NSString * const kCloudXChannelCode = @"Y+H6DFttYrPQYcIAicKwJQKQYrN=";

static NSString * const kIABTCF_gdprApplies = @"IABTCF_gdprApplies";
static NSString * const kIABUSPrivacy_String = @"IABUSPrivacy_String";

@interface CLXMintegralInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMintegralInitializer

static NSInteger sInitializationStatus = 0; // 0 = uninitialized, 1 = initializing, 2 = initialized, -1 = failed

+ (BOOL)isInitialized {
    return sInitializationStatus == 2;
}

+ (instancetype)createInstance {
    return [[CLXMintegralInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    return [MTGSDK sdkVersion];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLXMintegralInitializer sdkVersion];
        _network = @"mintegral";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralInitializer"];
    }
    return self;
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {

    [self.logger debug:[NSString stringWithFormat:@"Initializing Mintegral adapter (testMode: %@)", testMode ? @"YES" : @"NO"]];
    // Note: testMode parameter received from server deviceConfig

    // Already initialized - return success immediately
    if (sInitializationStatus == 2) {
        [self.logger debug:@"Mintegral SDK already initialized"];
        if (completion) completion(YES, nil);
        return;
    }

    // Extract Mintegral-specific credentials from provisioning response
    NSString *appID = config.initializationData[@"appID"];
    NSString *appKey = config.initializationData[@"appKey"];

    if (!appID || appID.length == 0 || !appKey || appKey.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidConfiguration
                                     description:@"Missing Mintegral App ID or App Key"];
        [self.logger error:@"Failed to initialize Mintegral: missing App ID or App Key"];
        if (completion) completion(NO, error);
        return;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInitializationStatus = 1; // initializing

        @try {
            MTGSDK *mtgSDK = [MTGSDK sharedInstance];

            // Set channel code BEFORE initialization (for attribution)
            [self setChannelCode:mtgSDK];

            // Privacy must be configured BEFORE setAppID:ApiKey: — mirrors AppLovin adapter.
            // Mintegral also reads IAB TCF/USP strings from UserDefaults automatically,
            // but explicit API calls take precedence and guarantee correct behavior
            // even if UserDefaults aren't populated yet at init time.
            [self configurePrivacySettings:mtgSDK];

            [self.logger debug:[NSString stringWithFormat:@"Initializing Mintegral SDK with AppID: %@", appID]];

            // Initialize Mintegral SDK
            [mtgSDK setAppID:appID ApiKey:appKey];

            sInitializationStatus = 2; // initialized
            [self.logger info:[NSString stringWithFormat:@"Mintegral SDK initialized (v%@)",
                             [MTGSDK sdkVersion] ?: @"unknown"]];

        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"Mintegral initialization failed: %@", exception.reason]];
            sInitializationStatus = -1; // failed
        }
    });

    if (sInitializationStatus == 2) {
        if (completion) completion(YES, nil);
    } else {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInternalError
                                     description:@"Mintegral SDK initialization failed"];
        if (completion) completion(NO, error);
    }
}

- (void)configurePrivacySettings:(MTGSDK *)mtgSDK {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // GDPR: derive consent from IAB TCF gdprApplies flag.
    // If GDPR doesn't apply, mark consented. If it applies, absence of
    // a TC string means the user hasn't interacted with a CMP yet.
    NSNumber *gdprApplies = [defaults objectForKey:kIABTCF_gdprApplies];
    if (gdprApplies != nil) {
        BOOL hasConsent = (gdprApplies.integerValue != 1);
        mtgSDK.consentStatus = hasConsent;
        [self.logger debug:[NSString stringWithFormat:@"Set consentStatus=%@", hasConsent ? @"YES" : @"NO"]];
    }

    // CCPA: derive do-not-sell from IAB US Privacy String (1YNN format).
    // Index 2 == 'Y' means the user opted out of sale.
    NSString *usPrivacy = [defaults stringForKey:kIABUSPrivacy_String];
    if (usPrivacy.length >= 3) {
        unichar optOut = [usPrivacy characterAtIndex:2];
        if (optOut == 'Y') {
            mtgSDK.doNotTrackStatus = YES;
            [self.logger debug:@"Set doNotTrackStatus=YES (CCPA opt-out)"];
        }
    }
}

/**
 * Set the channel code so that logs generated by Mintegral SDK can be attributed to CloudX.
 *
 * NOTE: The channel code must be obtained from Mintegral directly. Contact your Mintegral
 * account representative to request a unique channel code for CloudX.
 */
- (void)setChannelCode:(MTGSDK *)mtgSDK {
    if (kCloudXChannelCode.length == 0) {
        return;
    }

    @try {
        Class mintegralSdkClass = [mtgSDK class];
        SEL setChannelFlagSelector = NSSelectorFromString(@"setChannelFlag:");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([mintegralSdkClass respondsToSelector:setChannelFlagSelector]) {
            [mintegralSdkClass performSelector:setChannelFlagSelector withObject:kCloudXChannelCode];
        }
#pragma clang diagnostic pop
    }
    @catch (NSException *exception) {
        [self.logger warn:[NSString stringWithFormat:@"Failed to set channel code: %@", exception.reason]];
    }
}

@end

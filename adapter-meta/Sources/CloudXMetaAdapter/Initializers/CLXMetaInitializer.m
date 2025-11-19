//
//  CLXMetaInitializer.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#if __has_include(<CloudXMetaAdapter/CLXMetaInitializer.h>)
#import <CloudXMetaAdapter/CLXMetaInitializer.h>
#else
#import "CLXMetaInitializer.h"
#endif
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyService.h>

// Import CloudXCore for both SPM and CocoaPods
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

// Import other internal headers for registration
#if __has_include(<CloudXMetaAdapter/CLXMetaBannerFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBannerFactory.h>
#else
#import "CLXMetaBannerFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaInterstitialFactory.h>)
#import <CloudXMetaAdapter/CLXMetaInterstitialFactory.h>
#else
#import "CLXMetaInterstitialFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaRewardedFactory.h>)
#import <CloudXMetaAdapter/CLXMetaRewardedFactory.h>
#else
#import "CLXMetaRewardedFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaNativeFactory.h>)
#import <CloudXMetaAdapter/CLXMetaNativeFactory.h>
#else
#import "CLXMetaNativeFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaBidTokenSource.h>)
#import <CloudXMetaAdapter/CLXMetaBidTokenSource.h>
#else
#import "CLXMetaBidTokenSource.h"
#endif

@interface CLXMetaInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL initialized;

// Private class method for internal logging
+ (CLXLogger *)logger;
@end

@implementation CLXMetaInitializer

+ (CLXLogger *)logger {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaInitializer"];
    });
    return logger;
}

static BOOL isInitialized = NO;
static NSString * const kSDKVersion = @"6.16.0"; // Facebook Audience Network SDK version

+ (BOOL)isInitialized {
    return isInitialized;
}

+ (instancetype)createInstance {
    return [[CLXMetaInitializer alloc] init];
}

+ (NSString *)sdkVersion {
    return kSDKVersion;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _sdkVersion = [CLXMetaInitializer sdkVersion];
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [[CLXMetaInitializer logger] debug:@"Initializing Meta Audience Network adapter"];
    
    // Configure production settings (always needed)
    [self configureAdvertiserTrackingEnabled];
    
    // Configure test settings (only for development/testing)
    // Check if running on simulator
    BOOL isSimulator = NO;
    #if TARGET_OS_SIMULATOR
        isSimulator = YES;
    #endif
    
    // Check UserDefaults override (for TestFlight/special cases)
    BOOL testModeOverride = [[NSUserDefaults standardUserDefaults] boolForKey:@"CLXMetaTestModeEnabled"];
    
    // Enable test mode if: Debug build, Simulator, or UserDefaults override
    if (isSimulator) {
        [[CLXMetaInitializer logger] info:@"📱 [CLXMetaInitializer] Running on simulator - enabling test mode"];
        [self configureTestSettings];
    }
    #ifdef DEBUG
    else {
        [[CLXMetaInitializer logger] info:@"Debug build - enabling test mode"];
        [self configureTestSettings];
    }
    #else
    else if (testModeOverride) {
        [[CLXMetaInitializer logger] info:@"⚠️ [CLXMetaInitializer] Test mode enabled via UserDefaults override"];
        [self configureTestSettings];
    }
    #endif
    
    // Initialize Meta FAN SDK with placement IDs like MAX does
    [self initializeMetaSDKWithConfig:config];
    
    isInitialized = YES;
    
    [[CLXMetaInitializer logger] info:@"Meta adapter initialization completed"];
    
    if (completion) {
        completion(YES, nil);
    }
}

#pragma mark - Private Methods

- (void)initializeMetaSDKWithConfig:(nullable CLXBidderConfig *)config {
    // Extract placement IDs from config if available
    NSMutableArray<NSString *> *placementIDs = [NSMutableArray array];
    
    if (config && config.initializationData) {
        NSArray *configPlacementIDs = config.initializationData[@"placementIds"];
        if ([configPlacementIDs isKindOfClass:[NSArray class]] && configPlacementIDs.count > 0) {
            [placementIDs addObjectsFromArray:configPlacementIDs];
            [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"Found bidder init data: %@ | Added %lu placement IDs", 
                                               config.initializationData, (unsigned long)placementIDs.count]];
        } else {
            [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"Found bidder init data: %@ | No valid placement IDs array", config.initializationData]];
        }
    }
    
    // Initialize Meta FAN SDK with placement IDs like MAX does
    if (placementIDs.count > 0) {
        [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"Initializing Meta FAN SDK with %lu placement IDs: %@", (unsigned long)placementIDs.count, [placementIDs componentsJoinedByString:@", "]]];
        
        void (^facebookCompletionHandler)(FBAdInitResults *results) = ^(FBAdInitResults *initResult) {
            [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"%@ [CLXMetaInitializer] Meta FAN SDK initialization %@: %@", 
                                               [initResult isSuccess] ? @"✅" : @"⚠️",
                                               [initResult isSuccess] ? @"successful" : @"completed",
                                               initResult.message ?: @"No message"]];
        };
        
        // Init FAN SDK with placement IDs for improved performance
        NSString *mediationIdentifier = [NSString stringWithFormat:@"CLOUDX_%@", kSDKVersion];
        FBAdInitSettings *initSettings = [[FBAdInitSettings alloc] initWithPlacementIDs:placementIDs mediationService:mediationIdentifier];
        [FBAudienceNetworkAds initializeWithSettings:initSettings completionHandler:facebookCompletionHandler];
    } else {
        [[CLXMetaInitializer logger] debug:@"No placement IDs available - using default Meta FAN SDK initialization"];
        
        // Still need to initialize Meta FAN SDK even without placement IDs
        void (^facebookCompletionHandler)(FBAdInitResults *results) = ^(FBAdInitResults *initResult) {
            [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"%@ [CLXMetaInitializer] Meta FAN SDK default initialization %@: %@", 
                                               [initResult isSuccess] ? @"✅" : @"⚠️",
                                               [initResult isSuccess] ? @"successful" : @"completed",
                                               initResult.message ?: @"No message"]];
        };
        
        // Initialize without placement IDs - Meta SDK will work with individual ad requests
        NSString *mediationIdentifier = [NSString stringWithFormat:@"CLOUDX_%@", kSDKVersion];
        FBAdInitSettings *initSettings = [[FBAdInitSettings alloc] initWithPlacementIDs:@[] mediationService:mediationIdentifier];
        [FBAudienceNetworkAds initializeWithSettings:initSettings completionHandler:facebookCompletionHandler];
    }
}

- (void)configureAdvertiserTrackingEnabled {
    // Use CloudX core's tracking service for consistency
    BOOL idfaAllowed = [CLXAdTrackingService isIDFAAccessAllowed];
    
    // Set Meta's ATE flag based on CloudX tracking service result
    [FBAdSettings setAdvertiserTrackingEnabled:idfaAllowed];
    
    [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"ATE flag set to %@ - Based on CloudX tracking service", 
                                      idfaAllowed ? @"YES" : @"NO"]];
    
    // Configure COPPA (mixed audience) setting
    [self configureCOPPASettings];
}

- (void)configureCOPPASettings {
    CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
    BOOL coppaEnabled = [privacyService isCoppaEnabled];
    
    // Meta requires mixedAudience=YES for apps with child users (COPPA compliance)
    // Note: Meta prohibits use in child-directed apps; this is for mixed-audience apps only
    [FBAdSettings setMixedAudience:coppaEnabled];
    
    [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"Meta mixedAudience set to %@ (COPPA %@)", 
                                      coppaEnabled ? @"YES" : @"NO",
                                      coppaEnabled ? @"enabled" : @"disabled"]];
}

/**
 * Configures Meta test settings for development/testing
 * 
 * Test mode can be enabled in two ways:
 * 1. Automatically in DEBUG builds
 * 2. Via UserDefaults override: [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLXMetaTestModeEnabled"];
 *
 * When enabled, registers the current device as a test device to receive test ads.
 * This only affects the current device - other users will see production ads.
 *
 * Note: Remember to disable UserDefaults override before final App Store release!
 */
- (void)configureTestSettings {
    // Dynamically get current device's test hash instead of hardcoding
    NSString *deviceHash = [FBAdSettings testDeviceHash];
    if (deviceHash && deviceHash.length > 0) {
        [FBAdSettings addTestDevice:deviceHash];
        [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"Test device registered dynamically: %@", deviceHash ? @"SUCCESS" : @"FAILED"]];
    } else {
        [[CLXMetaInitializer logger] debug:@"Unable to retrieve device test hash"];
    }
    
    // Set logging level for better debugging during development
    [FBAdSettings setLogLevel:FBAdLogLevelLog];
    
    // Check and log test mode status
    BOOL isTestMode = [FBAdSettings isTestMode];
    
    [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"Meta test mode: %@ | Debug logging enabled", isTestMode ? @"enabled" : @"disabled"]];
}

@end 

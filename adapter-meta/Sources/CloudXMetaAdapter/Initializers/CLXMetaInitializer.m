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
    [[CLXMetaInitializer logger] debug:@"🔧 [CLXMetaInitializer] Initializing Meta Audience Network adapter"];
    
    // Configure production settings (always needed)
    [self configureAdvertiserTrackingEnabled];
    
    // Configure test settings (only for development/testing)
    #ifdef DEBUG
    [self configureTestSettings];
    #endif
    
    // Initialize Meta FAN SDK with placement IDs like MAX does
    [self initializeMetaSDKWithConfig:config];
    
    isInitialized = YES;
    
    [[CLXMetaInitializer logger] info:@"✅ [CLXMetaInitializer] Meta adapter initialization completed"];
    
    if (completion) {
        completion(YES, nil);
    }
}

#pragma mark - Private Methods

- (void)initializeMetaSDKWithConfig:(nullable CLXBidderConfig *)config {
    // Extract placement IDs from config if available
    NSMutableArray<NSString *> *placementIDs = [NSMutableArray array];
    
    if (config && config.initializationData) {
        [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"🔍 [CLXMetaInitializer] Found bidder init data: %@", config.initializationData]];
        
        // Check for placementIds array in initializationData (server uses camelCase)
        NSArray *configPlacementIDs = config.initializationData[@"placementIds"];
        if ([configPlacementIDs isKindOfClass:[NSArray class]] && configPlacementIDs.count > 0) {
            [placementIDs addObjectsFromArray:configPlacementIDs];
            [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"✅ [CLXMetaInitializer] Found %lu placement IDs in bidder init data", (unsigned long)placementIDs.count]];
        }
    }
    
    // Initialize Meta FAN SDK with placement IDs like MAX does
    if (placementIDs.count > 0) {
        [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"✅ [CLXMetaInitializer] Initializing Meta FAN SDK with %lu placement IDs: %@", (unsigned long)placementIDs.count, [placementIDs componentsJoinedByString:@", "]]];
        
        void (^facebookCompletionHandler)(FBAdInitResults *results) = ^(FBAdInitResults *initResult) {
            if ([initResult isSuccess]) {
                [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"✅ [CLXMetaInitializer] Meta FAN SDK initialization successful: %@", initResult.message ?: @"No message"]];
            } else {
                [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"⚠️ [CLXMetaInitializer] Meta FAN SDK initialization completed: %@", initResult.message ?: @"No message"]];
            }
        };
        
        // Init FAN SDK with placement IDs for improved performance
        NSString *mediationIdentifier = [NSString stringWithFormat:@"CLOUDX_%@", kSDKVersion];
        FBAdInitSettings *initSettings = [[FBAdInitSettings alloc] initWithPlacementIDs:placementIDs mediationService:mediationIdentifier];
        [FBAudienceNetworkAds initializeWithSettings:initSettings completionHandler:facebookCompletionHandler];
    } else {
        [[CLXMetaInitializer logger] debug:@"🔧 [CLXMetaInitializer] No placement IDs available - using default Meta FAN SDK initialization"];
        
        // Still need to initialize Meta FAN SDK even without placement IDs
        void (^facebookCompletionHandler)(FBAdInitResults *results) = ^(FBAdInitResults *initResult) {
            if ([initResult isSuccess]) {
                [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"✅ [CLXMetaInitializer] Meta FAN SDK default initialization successful: %@", initResult.message ?: @"No message"]];
            } else {
                [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"⚠️ [CLXMetaInitializer] Meta FAN SDK default initialization completed: %@", initResult.message ?: @"No message"]];
            }
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
    
    [[CLXMetaInitializer logger] info:[NSString stringWithFormat:@"📊 [CLXMetaInitializer] ATE flag set to %@ - Based on CloudX tracking service", 
                                      idfaAllowed ? @"YES" : @"NO"]];
}

- (void)configureTestSettings {
    // Dynamically get current device's test hash instead of hardcoding
    NSString *deviceHash = [FBAdSettings testDeviceHash];
    if (deviceHash && deviceHash.length > 0) {
        [FBAdSettings addTestDevice:deviceHash];
        [[CLXMetaInitializer logger] debug:@"Test device registered dynamically"];
    } else {
        [[CLXMetaInitializer logger] info:@"Unable to retrieve device test hash"];
    }
    
    // Set logging level for better debugging during development
    [FBAdSettings setLogLevel:FBAdLogLevelLog];
    
    // Check and log test mode status
    BOOL isTestMode = [FBAdSettings isTestMode];
    
    [[CLXMetaInitializer logger] debug:[NSString stringWithFormat:@"Meta test mode: %@", isTestMode ? @"enabled" : @"disabled"]];
    [[CLXMetaInitializer logger] debug:@"Meta debug logging enabled"];
}

// Ensure classes are loaded for static frameworks
__attribute__((visibility("default"))) void CloudXMetaAdapterRegister(void) {
    // Create a local logger for registration - avoid exposing internal logger publicly
    static CLXLogger *registrationLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        registrationLogger = [[CLXLogger alloc] initWithCategory:@"MetaAdapterRegistration"];
    });
    
    [registrationLogger debug:@"Loading Meta adapter classes"];
    
    // Force load all classes by referencing them
    [CLXMetaInitializer class];
    [CLXMetaBannerFactory class];
    [CLXMetaInterstitialFactory class];
    [CLXMetaRewardedFactory class];
    [CLXMetaNativeFactory class];
    [CLXMetaBidTokenSource class];
    
    [registrationLogger debug:@"Meta adapter classes loaded successfully"];
}

// Call registration during class load
+ (void)load {
    CloudXMetaAdapterRegister();
}

@end 

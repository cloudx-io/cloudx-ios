//
//  CLXVungleInitializer.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleInitializer.h"
#import "CLXVungleErrorHandler.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

// Import factory headers for registration
#import "CLXVungleBannerFactory.h"
#import "CLXVungleInterstitialFactory.h"
#import "CLXVungleRewardedFactory.h"
#import "CLXVungleNativeFactory.h"
#import "CLXVungleAppOpenFactory.h"
#import "CLXVungleBidTokenSource.h"

@interface CLXVungleInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isInitializing;
@property (nonatomic, strong) NSMutableArray<void (^)(BOOL success, NSError * _Nullable error)> *pendingCompletions;
@end

@implementation CLXVungleInitializer

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"VungleInitializer"];
        _isInitializing = NO;
        _pendingCompletions = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

#pragma mark - Public Methods

+ (BOOL)isInitialized {
    return [VungleAds isInitialized];
}

+ (NSString *)sdkVersion {
    return [VungleAds sdkVersion] ?: @"unknown";
}

- (NSString *)sdkVersion {
    return [[self class] sdkVersion];
}

- (NSString *)network {
    return @"Vungle";
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config 
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    // Note: testMode parameter received from server deviceConfig - Vungle doesn't require explicit test mode setting
    
    // Ensure we have a completion block
    void (^safeCompletion)(BOOL, NSError *) = completion ?: ^(BOOL success, NSError *error) {};
    
    // Check if already initialized
    if ([VungleAds isInitialized]) {
        [self.logger info:@"Vungle SDK already initialized"];
        dispatch_async(dispatch_get_main_queue(), ^{
            safeCompletion(YES, nil);
        });
        return;
    }
    
    // Check if initialization is in progress
    if (self.isInitializing) {
        [self.logger info:@"Vungle SDK initialization already in progress, queuing completion"];
        @synchronized(self.pendingCompletions) {
            [self.pendingCompletions addObject:[safeCompletion copy]];
        }
        return;
    }
    
    // Extract App ID from config
    NSString *appId = [self extractAppIdFromConfig:config];
    if (!appId) {
        NSError *error = [NSError errorWithDomain:CLXVungleAdapterErrorDomain
                                             code:CLXVungleAdapterErrorCodeInvalidConfiguration
                                         userInfo:@{
                                             NSLocalizedDescriptionKey: @"Vungle App ID is required for initialization",
                                             NSLocalizedFailureReasonErrorKey: @"No app_id found in configuration"
                                         }];
        
        [self.logger error:[NSString stringWithFormat:@"Initialization failed: %@", error.localizedDescription]];
        dispatch_async(dispatch_get_main_queue(), ^{
            safeCompletion(NO, error);
        });
        return;
    }
    
    // Start initialization
    self.isInitializing = YES;
    @synchronized(self.pendingCompletions) {
        [self.pendingCompletions addObject:[safeCompletion copy]];
    }
    
    [self.logger info:[NSString stringWithFormat:@"Initializing Vungle SDK with App ID: %@", appId]];
    
    // Configure privacy settings BEFORE initialization (Vungle requirement)
    [self configurePrivacySettings];
    
    // Initialize Vungle SDK
    [VungleAds initWithAppId:appId completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleInitializationCompletion:error];
        });
    }];
}

#pragma mark - Private Methods

- (nullable NSString *)extractAppIdFromConfig:(nullable CLXBidderConfig *)config {
    if (!config) {
        [self.logger error:@"No configuration provided"];
        return nil;
    }
    
    // Try different possible keys for app ID
    NSArray *possibleKeys = @[@"appID", @"app_id", @"vungle_app_id", @"appId", @"application_id"];
    
    for (NSString *key in possibleKeys) {
        NSString *appId = config.initializationData[key];
        if (appId && appId.length > 0) {
            [self.logger debug:[NSString stringWithFormat:@"Found App ID using key '%@': %@", key, appId]];
            return appId;
        }
    }
    
    // No App ID found in configuration
    [self.logger error:@"Vungle App ID not found in initialization data"];
    return nil;
}

- (void)handleInitializationCompletion:(NSError * _Nullable)error {
    self.isInitializing = NO;
    
    BOOL success = (error == nil);
    NSError *finalError = error;
    
    if (success) {
        [self.logger info:@"Vungle SDK initialization completed successfully"];
    } else {
        finalError = [CLXVungleErrorHandler mapVungleError:error context:@"Initialization"];
        [self.logger error:[NSString stringWithFormat:@"Vungle SDK initialization failed: %@", finalError.localizedDescription]];
    }
    
    // Call all pending completions
    NSArray *completions;
    @synchronized(self.pendingCompletions) {
        completions = [self.pendingCompletions copy];
        [self.pendingCompletions removeAllObjects];
    }
    
    for (void (^completion)(BOOL, NSError *) in completions) {
        completion(success, finalError);
    }
}

#pragma mark - Privacy Settings

- (void)configurePrivacySettings {
    // GDPR - Vungle reads IAB TCF strings automatically from UserDefaults
    
    // CCPA - Vungle reads IAB US Privacy strings automatically from UserDefaults
    // Note: Most mediation platforms let the SDK read IAB strings directly from UserDefaults
}

@end

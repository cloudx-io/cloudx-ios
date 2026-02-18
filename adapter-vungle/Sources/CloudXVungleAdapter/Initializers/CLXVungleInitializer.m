//
//  CLXVungleInitializer.m
//  CloudXVungleAdapter
//

#import "CLXVungleInitializer.h"
#import "CLXVungleAdapterVersion.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleInitializer ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXVungleInitializer

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXVungleInitializer"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[self alloc] init];
}

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

    if ([VungleAds isInitialized]) {
        [self.logger info:@"Vungle SDK already initialized"];
        completion(YES, nil);
        return;
    }

    NSString *appId = config.initializationData[@"appID"];

    if (!appId || appId.length == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidConfiguration
                                     description:@"Vungle App ID not found in configuration"];
        [self.logger error:error.localizedDescription];
        completion(NO, error);
        return;
    }

    [self.logger info:[NSString stringWithFormat:@"Initializing Vungle SDK with App ID: %@", appId]];

    [VungleAds setIntegrationName:@"cloudx" version:CLXVungleAdapterVersion];

    [VungleAds initWithAppId:appId completion:^(NSError * _Nullable error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Vungle SDK initialization failed: %@", error.localizedDescription]];
            completion(NO, error);
            return;
        }

        [self.logger info:@"Vungle SDK initialized successfully"];
        completion(YES, nil);
    }];
}

@end

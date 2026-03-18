//
//  CLXUnityAdsRewarded.m
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsRewarded.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsRewarded.h>
#else
#import "CLXUnityAdsRewarded.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXVersion.h>

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsErrorHandler.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsErrorHandler.h>
#else
#import "CLXUnityAdsErrorHandler.h"
#endif

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsInitializer.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsInitializer.h>
#else
#import "CLXUnityAdsInitializer.h"
#endif

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsAdapterVersion.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsAdapterVersion.h>
#else
#import "CLXUnityAdsAdapterVersion.h"
#endif

@interface CLXUnityAdsRewarded ()

@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *placementName;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, nullable) UADSRewardedAd *rewardedAd;
@property (nonatomic, assign) BOOL adLoaded;
@property (nonatomic, assign) BOOL rewarded;
@property (nonatomic, strong, nullable) CLXUnityAdsRewarded *showRetain;

@end

@implementation CLXUnityAdsRewarded

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _placementName = [placementName copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [UnityAds getVersion];
        _network = @"unityads";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsRewarded"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%@), BidID: %@",
                           placementName ?: @"(unknown)", placementID ?: @"(nil)", bidID]];
    }
    return self;
}

- (BOOL)isReady {
    return _adLoaded;
}

- (UADSMediationInfo *)mediationInfo {
    return [[UADSMediationInfo alloc] initWithName:@"cloudx"
                                           version:CLXSDKVersion
                                    adapterVersion:CLXUnityAdsAdapterVersion];
}

- (void)load {
    if (!_placementID || _placementID.length == 0) {
        NSString *placementContext = _placementName ? [NSString stringWithFormat:@" for placement '%@'", _placementName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Unity Ads placement ID is empty%@. "
                                  "Configure the placement ID in CloudX dashboard under Ad Unit Settings > Unity Ads.",
                                  placementContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];

        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            [self.delegate didFailToLoadWithRewarded:self error:error];
        }
        return;
    }

    if (![CLXUnityAdsInitializer isInitialized]) {
        NSString *message = @"Unity Ads SDK not initialized";
        [self.logger error:message];
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterNotInitialized description:message];
        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            [self.delegate didFailToLoadWithRewarded:self error:error];
        }
        return;
    }

    [self.logger debug:[NSString stringWithFormat:@"Loading rewarded - Placement: %@", _placementID]];

    UADSLoadConfigurationBuilder *builder = [[[UADSLoadConfigurationBuilder alloc]
        initWithPlacementId:_placementID]
        withMediationInfo:[self mediationInfo]];
    if (self.bidPayload) {
        builder = [builder withAdMarkup:self.bidPayload];
    }
    UADSLoadConfiguration *loadConfig = [builder build];

    __weak typeof(self) weakSelf = self;
    [UADSRewardedAd load:loadConfig completion:^(UADSRewardedAd *ad, id<UnityAdsError> error) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Rewarded load failed - Placement: %@, Error: %ld, Message: %@",
                                     strongSelf.placementID, (long)error.code, error.message]];

            CLXError *clxError = [CLXUnityAdsErrorHandler toCloudXError:error];

            if ([strongSelf.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
                [strongSelf.delegate didFailToLoadWithRewarded:strongSelf error:clxError];
            }
            return;
        }

        [strongSelf.logger info:[NSString stringWithFormat:@"Rewarded loaded - Placement: %@", strongSelf.placementID]];

        strongSelf.rewardedAd = ad;
        strongSelf->_adLoaded = YES;

        // Register expiry handler
        ad.onAdExpired = ^(UnityAd *expiredAd) {
            typeof(self) innerSelf = weakSelf;
            if (!innerSelf) return;

            [innerSelf.logger info:@"Rewarded ad expired"];
            innerSelf->_adLoaded = NO;
            innerSelf.rewardedAd = nil;

            if ([innerSelf.delegate respondsToSelector:@selector(expiredWithRewarded:)]) {
                [innerSelf.delegate expiredWithRewarded:innerSelf];
            }
        };

        if ([strongSelf.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
            [strongSelf.delegate didLoadWithRewarded:strongSelf];
        }
    }];
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (!self.rewardedAd) {
        [self.logger warn:@"Rewarded ad not ready to show"];
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterAdNotReady
                                      description:@"Rewarded ad is not loaded or ready to show"];
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
            [self.delegate didFailToShowWithRewarded:self error:error];
        }
        return;
    }

    [self.logger info:@"Showing rewarded"];

    UADSShowConfiguration *showConfig = [[[[UADSShowConfigurationBuilder alloc] init]
        withViewController:viewController]
        build];

    self.showRetain = self; // prevent dealloc while Unity Ads is showing (Unity Ads SDK uses weak delegate refs)
    [self.rewardedAd show:showConfig delegate:self];
}

- (void)destroy {
    [self.logger debug:@"Destroying rewarded"];
    self.rewardedAd = nil;
    self.delegate = nil;
    _adLoaded = NO;
}

#pragma mark - UADSRewardedShowDelegate

- (void)showDidStart:(UnityAd *)unityAd {
    [self.logger info:@"Rewarded displayed"];

    if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
        [self.delegate didShowWithRewarded:self];
    }

    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

- (void)showDidClick:(UnityAd *)unityAd {
    [self.logger info:@"Rewarded clicked"];

    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
}

- (void)showDidReceiveReward:(UnityAd *)unityAd {
    [self.logger info:@"Rewarded user earned reward (deferred to close)"];
    _rewarded = YES;
}

- (void)showDidComplete:(UnityAd *)unityAd with:(UADSShowFinishState)state {
    [self.logger info:[NSString stringWithFormat:@"Rewarded hidden - State: %ld", (long)state]];

    if (_rewarded) {
        if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
            [self.delegate userRewardWithRewarded:self];
        }
    }

    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
    }
    self.showRetain = nil;
}

- (void)showDidFail:(UnityAd *)unityAd error:(id<UnityAdsError>)error {
    [self.logger error:[NSString stringWithFormat:@"Rewarded show failed - Error: %ld, Message: %@",
                       (long)error.code, error.message]];

    CLXError *clxError = [CLXUnityAdsErrorHandler toCloudXError:error];

    if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        [self.delegate didFailToShowWithRewarded:self error:clxError];
    }
    self.showRetain = nil;
}

@end

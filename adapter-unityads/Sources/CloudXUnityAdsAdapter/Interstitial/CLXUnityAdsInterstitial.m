//
//  CLXUnityAdsInterstitial.m
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsInterstitial.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsInterstitial.h>
#else
#import "CLXUnityAdsInterstitial.h"
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

@interface CLXUnityAdsInterstitial ()

@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *placementName;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, nullable) UADSInterstitialAd *interstitialAd;
@property (nonatomic, strong, nullable) CLXUnityAdsInterstitial *showRetain;

@end

@implementation CLXUnityAdsInterstitial

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _placementName = [placementName copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [UnityAds getVersion];
        _network = @"unityAds";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsInterstitial"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%@), BidID: %@",
                           placementName ?: @"(unknown)", placementID ?: @"(nil)", bidID]];
    }
    return self;
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

        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            [self.delegate didFailToLoadWithInterstitial:self error:error];
        }
        return;
    }

    if (![CLXUnityAdsInitializer isInitialized]) {
        NSString *message = @"Unity Ads SDK not initialized";
        [self.logger error:message];
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterNotInitialized description:message];
        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            [self.delegate didFailToLoadWithInterstitial:self error:error];
        }
        return;
    }

    [self.logger debug:[NSString stringWithFormat:@"Loading interstitial - Placement: %@", _placementID]];

    UADSLoadConfigurationBuilder *builder = [[[UADSLoadConfigurationBuilder alloc]
        initWithPlacementId:_placementID]
        withMediationInfo:[self mediationInfo]];
    if (self.bidPayload) {
        builder = [builder withAdMarkup:self.bidPayload];
    }
    UADSLoadConfiguration *loadConfig = [builder build];

    __weak typeof(self) weakSelf = self;
    [UADSInterstitialAd load:loadConfig completion:^(UADSInterstitialAd *ad, id<UnityAdsError> error) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Interstitial load failed - Placement: %@, Error: %ld, Message: %@",
                                     strongSelf.placementID, (long)error.code, error.message]];

            CLXError *clxError = [CLXUnityAdsErrorHandler toCloudXError:error];

            if ([strongSelf.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
                [strongSelf.delegate didFailToLoadWithInterstitial:strongSelf error:clxError];
            }
            return;
        }

        [strongSelf.logger info:[NSString stringWithFormat:@"Interstitial loaded - Placement: %@", strongSelf.placementID]];

        strongSelf.interstitialAd = ad;

        // Register expiry handler
        ad.onAdExpired = ^(UnityAd *expiredAd) {
            typeof(self) innerSelf = weakSelf;
            if (!innerSelf) return;

            [innerSelf.logger info:@"Interstitial ad expired"];
            innerSelf.interstitialAd = nil;

            if ([innerSelf.delegate respondsToSelector:@selector(expiredWithInterstitial:)]) {
                [innerSelf.delegate expiredWithInterstitial:innerSelf];
            }
        };

        if ([strongSelf.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
            [strongSelf.delegate didLoadWithInterstitial:strongSelf];
        }
    }];
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (!self.interstitialAd) {
        [self.logger warn:@"Interstitial ad not ready to show"];
        CLXError *error = [CLXError errorWithCode:CLXErrorCodeAdapterAdNotReady
                                      description:@"Interstitial ad is not loaded or ready to show"];
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
            [self.delegate didFailToShowWithInterstitial:self error:error];
        }
        return;
    }

    [self.logger info:@"Showing interstitial"];

    UADSShowConfiguration *showConfig = [[[[UADSShowConfigurationBuilder alloc] init]
        withViewController:viewController]
        build];

    self.showRetain = self; // prevent dealloc while Unity Ads is showing (Unity Ads SDK uses weak delegate refs)
    [self.interstitialAd show:showConfig delegate:self];
}

- (void)destroy {
    [self.logger debug:@"Destroying interstitial"];
    self.interstitialAd = nil;
    self.delegate = nil;
}

#pragma mark - UADSInterstitialShowDelegate

- (void)showDidStart:(UnityAd *)unityAd {
    [self.logger info:@"Interstitial displayed"];

    if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
        [self.delegate didShowWithInterstitial:self];
    }

    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)showDidClick:(UnityAd *)unityAd {
    [self.logger info:@"Interstitial clicked"];

    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

- (void)showDidComplete:(UnityAd *)unityAd with:(UADSShowFinishState)state {
    [self.logger info:[NSString stringWithFormat:@"Interstitial hidden - State: %ld", (long)state]];

    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
    self.showRetain = nil;
}

- (void)showDidFail:(UnityAd *)unityAd error:(id<UnityAdsError>)error {
    [self.logger error:[NSString stringWithFormat:@"Interstitial show failed - Error: %ld, Message: %@",
                       (long)error.code, error.message]];

    CLXError *clxError = [CLXUnityAdsErrorHandler toCloudXError:error];

    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:self error:clxError];
    }
    self.showRetain = nil;
}

@end

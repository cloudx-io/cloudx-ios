//
//  CLXUnityAdsBanner.m
//  CloudXUnityAdsAdapter
//

#if __has_include(<CloudXUnityAdsAdapter/CLXUnityAdsBanner.h>)
#import <CloudXUnityAdsAdapter/CLXUnityAdsBanner.h>
#else
#import "CLXUnityAdsBanner.h"
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

@interface CLXUnityAdsBanner ()

@property (nonatomic, strong, nullable) UADSBannerAd *unityBannerAd;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *placementName;
@property (nonatomic, assign) CLXBannerType bannerType;
@property (nonatomic, strong) CLXLogger *logger;

@end

@implementation CLXUnityAdsBanner

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type
                          delegate:(id<CLXAdapterBannerDelegate>)delegate {

    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _placementName = [placementName copy];
        _bidID = [bidID copy];
        _bannerType = type;
        _delegate = delegate;
        _sdkVersion = [UnityAds getVersion];
        _network = @"unityads";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXUnityAdsBanner"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%@), BidID: %@, Type: %ld",
                           placementName ?: @"(unknown)", placementID ?: @"(nil)", bidID, (long)type]];
    }
    return self;
}

- (UIView *)bannerView {
    return _unityBannerAd.view;
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

        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }

    if (![CLXUnityAdsInitializer isInitialized]) {
        NSString *message = @"Unity Ads SDK not initialized";
        [self.logger error:message];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterNotInitialized description:message];
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }

    [self.logger debug:[NSString stringWithFormat:@"Loading banner - Placement: %@", _placementID]];

    CGSize bannerSize = [self bannerSizeForType:self.bannerType];

    UADSBannerLoadConfigurationBuilder *builder = [[[UADSBannerLoadConfigurationBuilder alloc]
        initWithPlacementId:_placementID bannerSize:bannerSize delegate:self]
        withMediationInfo:[self mediationInfo]];
    if (self.bidPayload) {
        builder = [builder withAdMarkup:self.bidPayload];
    }
    UADSBannerLoadConfiguration *bannerConfig = [builder build];

    __weak typeof(self) weakSelf = self;
    [UADSBannerAd load:bannerConfig completion:^(UADSBannerAd *bannerAd, id<UnityAdsError> error) {
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Banner load failed: %ld - %@",
                                     (long)error.code, error.message]];

            CLXError *clxError = [CLXUnityAdsErrorHandler toCloudXError:error];

            if ([strongSelf.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
                [strongSelf.delegate failToLoadBanner:strongSelf error:clxError];
            }
            return;
        }

        [strongSelf.logger info:@"Banner loaded"];

        strongSelf.unityBannerAd = bannerAd;

        // Register expiry handler — no delegate callback for banner expiry
        bannerAd.onAdExpired = ^(UADSBannerAd *expiredAd) {
            typeof(self) innerSelf = weakSelf;
            if (!innerSelf) return;

            [innerSelf.logger info:@"Banner ad expired"];
            innerSelf.unityBannerAd = nil;
        };

        if ([strongSelf.delegate respondsToSelector:@selector(didLoadBanner:)]) {
            [strongSelf.delegate didLoadBanner:strongSelf];
        }
    }];
}

- (void)showFromViewController:(UIViewController *)viewController {
    // Banner is inline — no-op for show
}

- (void)destroy {
    [self.logger debug:@"Destroying banner"];

    UADSBannerAd *adToDestroy = self.unityBannerAd;
    self.unityBannerAd = nil;

    if (adToDestroy) {
        UIView *viewToRemove = adToDestroy.view;
        if (viewToRemove) {
            if ([NSThread isMainThread]) {
                [viewToRemove removeFromSuperview];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [viewToRemove removeFromSuperview];
                });
            }
        }
    }

    self.delegate = nil;
}

#pragma mark - UADSBannerAdDelegate

- (void)bannerImpression:(UADSBannerAd *)banner {
    [self.logger info:@"Banner impression"];

    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }

    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

- (void)bannerDidClick:(UADSBannerAd *)banner {
    [self.logger info:@"Banner clicked"];

    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)bannerDidFailShow:(UADSBannerAd *)banner error:(id<UnityAdsError>)error {
    [self.logger error:[NSString stringWithFormat:@"Banner show failed: %ld - %@",
                       (long)error.code, error.message]];

    // CLXAdapterBannerDelegate has no show-failure callback — report as load failure
    CLXError *clxError = [CLXUnityAdsErrorHandler toCloudXError:error];

    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:clxError];
    }
}

#pragma mark - Helpers

- (CGSize)bannerSizeForType:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeMREC:
            return CGSizeMake(300, 250);
        case CLXBannerTypeW320H50:
        default: {
            // iPad gets 728x90 (leader), iPhone gets 320x50 (standard)
            if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                return CGSizeMake(728, 90);
            }
            return CGSizeMake(320, 50);
        }
    }
}

@end

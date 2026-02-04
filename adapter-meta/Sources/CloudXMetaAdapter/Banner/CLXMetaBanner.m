//
//  CLXMetaBanner.m
//  CloudXMetaAdapter
//

#import "CLXMetaBanner.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXMetaAdapter/CLXMetaErrorHandler.h>)
#import <CloudXMetaAdapter/CLXMetaErrorHandler.h>
#else
#import "CLXMetaErrorHandler.h"
#endif

@interface CLXMetaBanner ()

@property (nonatomic, strong, nullable) FBAdView *bannerView;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy, nullable) NSString *placementID;
/// CloudX ad unit name for error messages (separate from Meta's placementID)
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) CLXBannerType type;
@property (nonatomic, strong) CLXLogger *logger;

@end

@implementation CLXMetaBanner

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            bidID:(NSString *)bidID
                             type:(CLXBannerType)type
                    viewController:(UIViewController *)viewController
                         delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;
        _adUnitName = adUnitName;
        _bidID = bidID;
        _type = type;
        _viewController = viewController;
        _delegate = delegate;
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaBanner"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%@), BidID: %@, Type: %ld, HasBidPayload: %@",
                           adUnitName ?: @"(unknown)", placementID ?: @"(nil)", bidID, (long)type, bidPayload ? @"YES" : @"NO"]];
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (BOOL)clx_isFlexibleSize {
    return YES;
}

- (void)load {
    if (!_placementID || _placementID.length == 0) {
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Meta placement ID is empty%@. "
                                  "Configure the Meta placement ID in CloudX dashboard under Ad Unit Settings > Meta.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];

        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }

    [self.logger debug:[NSString stringWithFormat:@"Loading banner - Placement: %@", _placementID]];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (!strongSelf.bannerView) {
            FBAdSize adSize = [strongSelf fbAdSizeForType:strongSelf.type];
            strongSelf.bannerView = [[FBAdView alloc] initWithPlacementID:strongSelf.placementID
                                                                   adSize:adSize
                                                       rootViewController:strongSelf.viewController];
            strongSelf.bannerView.frame = CGRectMake(0, 0, adSize.size.width, adSize.size.height);
            strongSelf.bannerView.delegate = strongSelf;
        }

        if (strongSelf.bidPayload) {
            [strongSelf.bannerView loadAdWithBidPayload:strongSelf.bidPayload];
        } else {
            [strongSelf.bannerView loadAd];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (UIView *)adView {
    return _bannerView;
}

- (void)showFromViewController:(UIViewController *)viewController {
    // Banner is shown when added to view hierarchy, nothing to do here
    [self.logger debug:@"showFromViewController called - banner shows when added to view"];
}

- (void)destroy {
    [self.logger debug:@"Destroying banner"];

    FBAdView *viewToDestroy = self.bannerView;
    self.bannerView = nil;

    if (viewToDestroy) {
        if ([NSThread isMainThread]) {
            viewToDestroy.delegate = nil;
            [viewToDestroy removeFromSuperview];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                viewToDestroy.delegate = nil;
                [viewToDestroy removeFromSuperview];
            });
        }
    }
}

#pragma mark - FBAdViewDelegate

- (void)adViewDidLoad:(FBAdView *)adView {
    [self.logger info:@"Banner ad loaded"];

    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    }
}

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Banner load failed: %@", error.localizedDescription]];
    CLXError *clxError = [CLXMetaErrorHandler toCloudXError:error];

    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:clxError];
    }
}

- (void)adViewDidClick:(FBAdView *)adView {
    [self.logger info:@"Ad clicked"];

    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
}

- (void)adViewWillLogImpression:(FBAdView *)adView {
    [self.logger info:@"Ad impression logged"];
    
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

- (UIViewController *)viewControllerForPresentingModalView {
    return self.viewController ?: [self topViewController];
}

#pragma mark - Helpers

- (FBAdSize)fbAdSizeForType:(CLXBannerType)type {
    switch (type) {
        case CLXBannerTypeMREC:
            return kFBAdSizeHeight250Rectangle;
        case CLXBannerTypeW320H50:
        default:
            return kFBAdSizeHeight50Banner;
    }
}

- (UIViewController *)topViewController {
    UIViewController *rootVC = nil;
    
    if (@available(iOS 13.0, *)) {
        NSSet *scenes = [UIApplication sharedApplication].connectedScenes;
        for (UIWindowScene *scene in scenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        rootVC = window.rootViewController;
                        break;
                    }
                }
                if (rootVC) break;
            }
        }
    }
    
    if (!rootVC) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        #pragma clang diagnostic pop
    }
    
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    return rootVC;
}

@end

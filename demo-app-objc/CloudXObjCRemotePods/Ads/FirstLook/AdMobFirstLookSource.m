#import "AdMobFirstLookSource.h"
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <QuartzCore/QuartzCore.h>
#import "DemoAppLogger.h"

static CFTimeInterval const kAdTimeToLive = 60 * 60;

@interface AdMobFirstLookSource () <GADFullScreenContentDelegate>
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, strong, nullable) GADInterstitialAd *ad;
@property (nonatomic) CFTimeInterval loadedAt;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL disposed;
@end

@implementation AdMobFirstLookSource

@synthesize onEvent = _onEvent;

- (instancetype)initWithViewController:(UIViewController *)viewController adUnitId:(NSString *)adUnitId {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _adUnitId = [adUnitId copy];
    }
    return self;
}

- (BOOL)isReady {
    if (self.disposed) return NO;
    if (self.ad && CACurrentMediaTime() - self.loadedAt >= kAdTimeToLive) {
        self.ad = nil;
    }
    return self.ad != nil;
}

- (void)load {
    if (self.disposed || self.loading || self.isReady) return;
    self.loading = YES;
    [[DemoAppLogger sharedInstance] logMessage:@"Loading AdMob interstitial fallback"];
    __weak typeof(self) weakSelf = self;
    [GADInterstitialAd loadWithAdUnitID:self.adUnitId
                                request:[GADRequest request]
                      completionHandler:^(GADInterstitialAd * _Nullable loadedAd, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.loading = NO;
        if (strongSelf.disposed) return;
        if (error) {
            [strongSelf emit:FirstLookEventTypeLoadFailed message:error.localizedDescription];
            return;
        }
        if (!loadedAd) {
            [strongSelf emit:FirstLookEventTypeLoadFailed message:@"No ad returned"];
            return;
        }
        strongSelf.ad = loadedAd;
        strongSelf.loadedAt = CACurrentMediaTime();
        loadedAd.fullScreenContentDelegate = strongSelf;
        [strongSelf emit:FirstLookEventTypeLoaded message:nil];
    }];
}

- (void)show {
    GADInterstitialAd *loadedAd = self.isReady ? self.ad : nil;
    UIViewController *viewController = self.viewController;
    if (!loadedAd || !viewController) {
        [self emit:FirstLookEventTypeShowFailed message:@"Ad is no longer ready"];
        return;
    }
    self.ad = nil;
    [loadedAd presentFromRootViewController:viewController];
}

- (void)dispose {
    self.disposed = YES;
    self.viewController = nil;
    self.ad.fullScreenContentDelegate = nil;
    self.ad = nil;
    self.onEvent = nil;
}

- (void)emit:(FirstLookEventType)type message:(nullable NSString *)message {
    if (self.disposed) return;
    FirstLookEventHandler onEvent = self.onEvent;
    if (onEvent) {
        onEvent([FirstLookEvent eventWithType:type source:FirstLookSourceAdMob message:message]);
    }
}

#pragma mark - GADFullScreenContentDelegate

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    [self emit:FirstLookEventTypeShown message:nil];
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    [self emit:FirstLookEventTypeClosed message:nil];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    [self emit:FirstLookEventTypeShowFailed message:error.localizedDescription];
}

- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad {
    [self emit:FirstLookEventTypeClicked message:nil];
}

@end

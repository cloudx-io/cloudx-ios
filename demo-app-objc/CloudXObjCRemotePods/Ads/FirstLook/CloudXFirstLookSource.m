#import "CloudXFirstLookSource.h"
#import <CloudXCore/CloudXCore.h>
#import "DemoAppLogger.h"

@interface CloudXFirstLookSource () <CLXInterstitialDelegate, CLXAdRevenueDelegate>
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, strong) CLXInterstitial *ad;
@end

@implementation CloudXFirstLookSource

@synthesize onEvent = _onEvent;

- (nullable instancetype)initWithViewController:(UIViewController *)viewController adUnitId:(NSString *)adUnitId {
    CLXInterstitial *ad = [[CloudXCore shared] createInterstitialWithAdUnitId:adUnitId];
    if (!ad) return nil;
    self = [super init];
    if (self) {
        _viewController = viewController;
        _ad = ad;
        ad.delegate = self;
        ad.revenueDelegate = self;
    }
    return self;
}

- (BOOL)isReady {
    return self.ad.isReady;
}

- (void)load {
    [self.ad load];
}

- (void)show {
    UIViewController *viewController = self.viewController;
    if (!viewController) {
        [self emit:FirstLookEventTypeShowFailed message:@"View controller unavailable"];
        return;
    }
    [self.ad showFromViewController:viewController];
}

- (void)dispose {
    self.viewController = nil;
    self.ad.delegate = nil;
    self.ad.revenueDelegate = nil;
    [self.ad destroy];
    self.onEvent = nil;
}

- (void)emit:(FirstLookEventType)type message:(nullable NSString *)message {
    FirstLookEventHandler onEvent = self.onEvent;
    if (onEvent) {
        onEvent([FirstLookEvent eventWithType:type source:FirstLookSourceCloudX message:message]);
    }
}

#pragma mark - CLXInterstitialDelegate

- (void)didLoadAd:(CLXAd *)ad {
    [self emit:FirstLookEventTypeLoaded message:nil];
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"CloudX interstitial failed to load: %@; trying AdMob", error.localizedDescription]];
    [self emit:FirstLookEventTypeLoadFailed message:error.localizedDescription];
}

- (void)didDisplayAd:(CLXAd *)ad {
    [self emit:FirstLookEventTypeShown message:nil];
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    [self emit:FirstLookEventTypeShowFailed message:error.localizedDescription];
}

- (void)didHideAd:(CLXAd *)ad {
    [self emit:FirstLookEventTypeClosed message:nil];
}

- (void)didClickAd:(CLXAd *)ad {
    [self emit:FirstLookEventTypeClicked message:nil];
}

#pragma mark - CLXAdRevenueDelegate

- (void)didPayRevenueForAd:(CLXAd *)ad {
    NSString *revenue = ad.revenue ? [NSString stringWithFormat:@"$%.6f", ad.revenue.doubleValue] : @"(null)";
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"CloudX interstitial revenue: %@", revenue]];
}

@end

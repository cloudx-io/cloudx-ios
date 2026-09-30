#import "ArbiterInterstitialController.h"
#import <CloudXCore/CloudXCore.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <QuartzCore/QuartzCore.h>
#import "DemoAppLogger.h"

static NSString * const kAdFormat = @"interstitial";
static CFTimeInterval const kAdMobAdTimeToLive = 60 * 60;

@interface ArbiterEvent ()
@property (nonatomic, readwrite) ArbiterEventType type;
@property (nonatomic, strong, readwrite, nullable) CLXArbiterPlatform *platform;
@property (nonatomic, copy, readwrite, nullable) NSString *message;
@property (nonatomic, readwrite) NSInteger bidCount;
@property (nonatomic, readwrite) double revenue;
@property (nonatomic, copy, readwrite, nullable) NSString *currencyCode;
@property (nonatomic, readwrite) BOOL accepted;
@end

@implementation ArbiterEvent

- (instancetype)initWithType:(ArbiterEventType)type platform:(nullable CLXArbiterPlatform *)platform {
    self = [super init];
    if (self) {
        _type = type;
        _platform = platform;
    }
    return self;
}

@end

@interface ArbiterInterstitialController () <CLXInterstitialDelegate, GADFullScreenContentDelegate>
@property (nonatomic, weak, nullable) UIViewController *viewController;
@property (nonatomic, copy) NSString *adMobAdUnitId;
@property (nonatomic, copy) ArbiterEventHandler onEvent;

/*
 * One CloudX ad object for the controller's lifetime: a load after the ad closes runs a new
 * auction on it. Nil when CloudX is not available.
 */
@property (nonatomic, strong, nullable) CLXInterstitial *cloudXInterstitial;
@property (nonatomic, strong, nullable) CLXAd *loadedCloudXAd;
@property (nonatomic) BOOL cloudXLoading;
@property (nonatomic) BOOL cloudXSettled;

@property (nonatomic, strong, nullable) GADInterstitialAd *adMobAd;
/*
 * A GADInterstitialAd is single-use, so a shown ad moves here. It stays alive until the next show
 * because AdMob can deliver the paid event after the ad was dismissed, and that revenue is what
 * prices the next AdMob bid.
 */
@property (nonatomic, strong, nullable) GADInterstitialAd *presentedAdMobAd;
@property (nonatomic) CFTimeInterval adMobLoadedAt;
@property (nonatomic) BOOL adMobLoading;
@property (nonatomic) BOOL adMobSettled;

@property (nonatomic, strong, nullable) CLXArbiterPlatform *nextWinner;
@property (nonatomic) BOOL arbiterInFlight;
@property (nonatomic, readwrite, getter=isShowing) BOOL showing;
@property (nonatomic) BOOL disposed;
@end

@implementation ArbiterInterstitialController

- (instancetype)initWithViewController:(UIViewController *)viewController
                        cloudXAdUnitId:(NSString *)cloudXAdUnitId
                         adMobAdUnitId:(NSString *)adMobAdUnitId
                       cloudXAvailable:(BOOL)cloudXAvailable
                               onEvent:(ArbiterEventHandler)onEvent {
    self = [super init];
    if (self) {
        _viewController = viewController;
        _adMobAdUnitId = [adMobAdUnitId copy];
        _onEvent = [onEvent copy];
        _cloudXInterstitial = cloudXAvailable ? [[CloudXCore shared] createInterstitialWithAdUnitId:cloudXAdUnitId] : nil;
        _cloudXSettled = _cloudXInterstitial == nil;
        if (cloudXAvailable && !_cloudXInterstitial) {
            [[DemoAppLogger sharedInstance] logMessage:@"CloudX interstitial unavailable; AdMob only"];
        }
        _cloudXInterstitial.delegate = self;
    }
    return self;
}

- (BOOL)isBusy {
    return self.cloudXLoading || self.adMobLoading || self.arbiterInFlight;
}

- (BOOL)cloudXReady {
    return self.loadedCloudXAd != nil && self.cloudXInterstitial.isReady;
}

/* A loaded AdMob interstitial can be shown once and expires after one hour. */
- (BOOL)adMobReady {
    if (self.adMobAd && CACurrentMediaTime() - self.adMobLoadedAt >= kAdMobAdTimeToLive) {
        self.adMobAd = nil;
    }
    return self.adMobAd != nil;
}

- (void)load {
    if (self.disposed || self.arbiterInFlight || self.showing) return;

    /*
     * Both settled flags are cleared before either load starts: CloudX can report a failure
     * inside its own load call, and the round must not run then on the other platform's result
     * from the previous round.
     */
    BOOL loadsCloudX = self.cloudXInterstitial != nil && !self.cloudXReady && !self.cloudXLoading;
    BOOL loadsAdMob = !self.adMobReady && !self.adMobLoading;
    if (loadsCloudX) {
        self.loadedCloudXAd = nil;
        self.cloudXSettled = NO;
        self.cloudXLoading = YES;
    }
    if (loadsAdMob) {
        self.adMobSettled = NO;
        self.adMobLoading = YES;
    }
    if (loadsCloudX) [self.cloudXInterstitial load];
    if (loadsAdMob) [self loadAdMob];

    /*
     * Both platforms may still hold their fills with no winner stored, after a round with no
     * winner or a winner that went stale. Nothing loads then, so the round runs from here.
     */
    if (!loadsCloudX && !loadsAdMob && !self.nextWinner) [self maybePrepareWinner];
}

- (nullable CLXArbiterPlatform *)show {
    UIViewController *host = self.viewController;
    CLXArbiterPlatform *winner = self.nextWinner;
    if (self.disposed || self.showing || !host || !winner) return nil;
    self.nextWinner = nil;

    if ([winner.name isEqualToString:CLXArbiterPlatform.cloudX.name]) {
        if (!self.cloudXInterstitial || !self.cloudXReady) {
            self.loadedCloudXAd = nil;
            return nil;
        }
        self.showing = YES;
        [self.cloudXInterstitial showFromViewController:host];
    } else if ([winner.name isEqualToString:CLXArbiterPlatform.adMob.name]) {
        GADInterstitialAd *ad = self.adMobReady ? self.adMobAd : nil;
        if (!ad) return nil;
        self.adMobAd = nil;
        self.presentedAdMobAd = ad;
        self.showing = YES;
        [ad presentFromRootViewController:host];
    } else {
        return nil;
    }
    return winner;
}

- (void)dispose {
    if (self.disposed) return;
    self.disposed = YES;
    self.viewController = nil;
    self.cloudXInterstitial.delegate = nil;
    [self.cloudXInterstitial destroy];
    self.adMobAd.fullScreenContentDelegate = nil;
    self.adMobAd.paidEventHandler = nil;
    self.presentedAdMobAd.fullScreenContentDelegate = nil;
    self.presentedAdMobAd.paidEventHandler = nil;
    self.adMobAd = nil;
    self.presentedAdMobAd = nil;
}

/*
 * Runs one round once both platforms have settled and stores the winner. The SDK owns the
 * timeout and the fallback, and always completes: a single bid wins without a service call, and
 * several bids go to the arbiter service or, when it is unavailable, to the highest locally
 * comparable price. So nothing here times the call out or compares prices.
 */
- (void)maybePrepareWinner {
    if (self.disposed || self.showing || self.arbiterInFlight || !self.cloudXSettled || !self.adMobSettled) return;

    NSMutableArray<CLXArbiterBid *> *bids = [NSMutableArray array];
    CLXAd *cloudXAd = self.loadedCloudXAd;
    if (cloudXAd && self.cloudXReady) {
        [bids addObject:[CLXArbiterBid cloudXBidWithAd:cloudXAd]];
    }
    GADInterstitialAd *adMobAd = self.adMobReady ? self.adMobAd : nil;
    if (adMobAd) {
        NSString *networkName = adMobAd.responseInfo.loadedAdNetworkResponseInfo.adSourceName ?: @"admob";
        [bids addObject:[CLXArbiterBid adMobBidWithAdUnitId:self.adMobAdUnitId
                                                networkName:networkName
                              manualRevenuePerImpressionUSD:nil
                                                     extras:nil]];
    }
    if (bids.count == 0) {
        [self emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeNoCandidates platform:nil]];
        return;
    }

    if (!self.cloudXInterstitial) {
        [[DemoAppLogger sharedInstance] logMessage:@"CloudX is not available, so the AdMob bid wins without an arbiter call"];
        [self storeWinner:CLXArbiterPlatform.adMob bidCount:bids.count];
        return;
    }

    self.arbiterInFlight = YES;
    NSInteger bidCount = bids.count;
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"Running the arbiter with %ld bid(s)", (long)bidCount]];
    CLXArbiterConfiguration *configuration = [CLXArbiterConfiguration configurationWithBids:bids];
    __weak typeof(self) weakSelf = self;
    [[CloudXCore shared] arbiterWithConfiguration:configuration completion:^(CLXArbiterResult *result) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.arbiterInFlight = NO;
        if (strongSelf.disposed) return;
        [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:
            @"Arbiter result: platform=%@ platformName=%@ id=%@ bidId=%@ bids=%ld",
            result.platform.name, result.platformName, result.identifier, result.bidId ?: @"-", (long)bidCount]];
        [strongSelf storeWinner:result.platform bidCount:bidCount];
    }];
}

/* NONE is not stored: a stored NONE would leave both fills held and no round left to run. */
- (void)storeWinner:(CLXArbiterPlatform *)platform bidCount:(NSInteger)bidCount {
    self.nextWinner = [platform.name isEqualToString:CLXArbiterPlatform.none.name] ? nil : platform;
    ArbiterEvent *event = [[ArbiterEvent alloc] initWithType:ArbiterEventTypeArbiterCompleted platform:platform];
    event.bidCount = bidCount;
    [self emit:event];
}

- (void)loadAdMob {
    __weak typeof(self) weakSelf = self;
    [GADInterstitialAd loadWithAdUnitID:self.adMobAdUnitId
                                request:[GADRequest request]
                      completionHandler:^(GADInterstitialAd * _Nullable ad, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.adMobLoading = NO;
        if (strongSelf.disposed) return;
        if (!ad) {
            strongSelf.adMobSettled = YES;
            [strongSelf emitFailure:ArbiterEventTypeLoadFailed
                           platform:CLXArbiterPlatform.adMob
                            message:error.localizedDescription ?: @"No ad returned"];
            [strongSelf maybePrepareWinner];
            return;
        }
        ad.fullScreenContentDelegate = strongSelf;
        __weak GADInterstitialAd *weakAd = ad;
        ad.paidEventHandler = ^(GADAdValue *adValue) {
            GADInterstitialAd *paidAd = weakAd;
            if (paidAd) [weakSelf reportAdMobPaidEvent:paidAd adValue:adValue];
        };
        strongSelf.adMobAd = ad;
        strongSelf.adMobLoadedAt = CACurrentMediaTime();
        strongSelf.adMobSettled = YES;
        [strongSelf emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeLoaded platform:CLXArbiterPlatform.adMob]];
        [strongSelf maybePrepareWinner];
    }];
}

/*
 * Required: this is how CloudX learns what an AdMob bid is worth. The iOS Google Mobile Ads SDK
 * reports the value in currency units, not micros, so it is passed through unchanged.
 */
- (void)reportAdMobPaidEvent:(GADInterstitialAd *)ad adValue:(GADAdValue *)adValue {
    GADAdNetworkResponseInfo *servedBy = ad.responseInfo.loadedAdNetworkResponseInfo;
    double revenue = adValue.value.doubleValue;
    NSString *adMobAdUnitId = self.adMobAdUnitId;
    CLXRevenueData *data = [CLXRevenueData revenueDataWithPlatform:CLXRevenuePlatformAdMob
                                                           revenue:revenue
                                                          adFormat:kAdFormat
                                                      builderBlock:^(CLXRevenueDataBuilder *builder) {
        builder.currencyCode = adValue.currencyCode;
        builder.precision = [ArbiterInterstitialController revenuePrecisionFrom:adValue.precision];
        builder.networkName = servedBy.adSourceName;
        builder.adUnitId = adMobAdUnitId;
        builder.thirdPartyAdPlacementId = servedBy.adSourceInstanceName;
    }];
    BOOL accepted = [[CloudXCore shared] reportRevenueData:data];
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"reportRevenueData(%@ %@) returned %@",
                                                adValue.value, adValue.currencyCode, accepted ? @"true" : @"false"]];
    ArbiterEvent *event = [[ArbiterEvent alloc] initWithType:ArbiterEventTypeRevenueReported platform:nil];
    event.revenue = revenue;
    event.currencyCode = adValue.currencyCode;
    event.accepted = accepted;
    [self emit:event];
}

+ (CLXRevenuePrecision *)revenuePrecisionFrom:(GADAdValuePrecision)precision {
    switch (precision) {
        case GADAdValuePrecisionPrecise: return CLXRevenuePrecision.exact;
        case GADAdValuePrecisionEstimated: return CLXRevenuePrecision.estimated;
        case GADAdValuePrecisionPublisherProvided: return CLXRevenuePrecision.publisherDefined;
        case GADAdValuePrecisionUnknown: return CLXRevenuePrecision.undefined;
    }
    return CLXRevenuePrecision.undefined;
}

- (void)emit:(ArbiterEvent *)event {
    if (!self.disposed) self.onEvent(event);
}

- (void)emitFailure:(ArbiterEventType)type platform:(CLXArbiterPlatform *)platform message:(NSString *)message {
    ArbiterEvent *event = [[ArbiterEvent alloc] initWithType:type platform:platform];
    event.message = message;
    [self emit:event];
}

#pragma mark - CLXInterstitialDelegate

- (void)didLoadAd:(CLXAd *)ad {
    if (self.disposed) return;
    self.cloudXLoading = NO;
    self.loadedCloudXAd = ad;
    self.cloudXSettled = YES;
    NSString *revenue = ad.revenue ? [NSString stringWithFormat:@"%.6f", ad.revenue.doubleValue] : @"(null)";
    [[DemoAppLogger sharedInstance] logMessage:[NSString stringWithFormat:@"CloudX bid from %@, revenue %@",
                                                ad.networkName ?: @"(null)", revenue]];
    [self emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeLoaded platform:CLXArbiterPlatform.cloudX]];
    [self maybePrepareWinner];
}

- (void)didFailToLoadAd:(NSString *)adUnitId error:(CLXError *)error {
    if (self.disposed) return;
    self.cloudXLoading = NO;
    self.loadedCloudXAd = nil;
    self.cloudXSettled = YES;
    [self emitFailure:ArbiterEventTypeLoadFailed platform:CLXArbiterPlatform.cloudX message:error.localizedDescription];
    [self maybePrepareWinner];
}

- (void)didDisplayAd:(CLXAd *)ad {
    [self emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeShown platform:CLXArbiterPlatform.cloudX]];
}

- (void)didFailToDisplayAd:(CLXAd *)ad error:(CLXError *)error {
    if (self.disposed) return;
    self.loadedCloudXAd = nil;
    self.showing = NO;
    [self emitFailure:ArbiterEventTypeShowFailed platform:CLXArbiterPlatform.cloudX message:error.localizedDescription];
}

- (void)didHideAd:(CLXAd *)ad {
    if (self.disposed) return;
    self.loadedCloudXAd = nil;
    self.showing = NO;
    [self emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeClosed platform:CLXArbiterPlatform.cloudX]];
}

- (void)didClickAd:(CLXAd *)ad {
    [self emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeClicked platform:CLXArbiterPlatform.cloudX]];
}

#pragma mark - GADFullScreenContentDelegate

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    [self emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeShown platform:CLXArbiterPlatform.adMob]];
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    if (self.disposed) return;
    self.showing = NO;
    [self emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeClosed platform:CLXArbiterPlatform.adMob]];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    if (self.disposed) return;
    self.showing = NO;
    [self emitFailure:ArbiterEventTypeShowFailed platform:CLXArbiterPlatform.adMob message:error.localizedDescription];
}

- (void)adDidRecordClick:(id<GADFullScreenPresentingAd>)ad {
    [self emit:[[ArbiterEvent alloc] initWithType:ArbiterEventTypeClicked platform:CLXArbiterPlatform.adMob]];
}

@end

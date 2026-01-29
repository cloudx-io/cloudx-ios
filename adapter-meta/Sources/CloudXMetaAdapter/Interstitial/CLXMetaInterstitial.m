//
//  CLXMetaInterstitial.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaInterstitial.h>)
#import <CloudXMetaAdapter/CLXMetaInterstitial.h>
#else
#import "CLXMetaInterstitial.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXMetaAdapter/CLXMetaErrorHandler.h>)
#import <CloudXMetaAdapter/CLXMetaErrorHandler.h>
#else
#import "CLXMetaErrorHandler.h"
#endif

@interface CLXMetaInterstitial ()

@property (nonatomic, strong) FBInterstitialAd *interstitial;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *placementName;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation CLXMetaInterstitial

- (instancetype)initWithBidPayload:(NSString *)bidPayload
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
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaInterstitial"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%@), BidID: %@",
                           placementName ?: @"(unknown)", placementID ?: @"(nil)", bidID]];

        if (placementID && placementID.length > 0) {
            _interstitial = [[FBInterstitialAd alloc] initWithPlacementID:placementID];
            _interstitial.delegate = self;
        }
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (BOOL)isReady {
    return _interstitial && _interstitial.isAdValid;
}

- (void)load {
    if (!_placementID || _placementID.length == 0) {
        NSString *placementContext = _placementName ? [NSString stringWithFormat:@" for placement '%@'", _placementName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Meta placement ID is empty%@. "
                                  "Configure the Meta placement ID in CloudX dashboard under Ad Unit Settings > Meta.",
                                  placementContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];

        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            [self.delegate didFailToLoadWithInterstitial:self error:error];
        }
        return;
    }

    if (!_interstitial) {
        _interstitial = [[FBInterstitialAd alloc] initWithPlacementID:_placementID];
        _interstitial.delegate = self;
    }

    if (_isLoading) {
        return;
    }

    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading interstitial - Placement: %@", _placementID]];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (strongSelf.bidPayload) {
            [strongSelf.interstitial loadAdWithBidPayload:strongSelf.bidPayload];
        } else {
            [strongSelf.interstitial loadAd];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (![self isReady]) {
        [self.logger error:@"Unable to show interstitial - ad is not valid, marking as expired"];
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdapterAdExpired
                                         description:@"Ad expired"];
        [self.delegate didFailToShowWithInterstitial:self error:showError];
        return;
    }

    [self.logger info:@"Showing interstitial"];
    [_interstitial showAdFromRootViewController:viewController];
}

- (void)destroy {
    [self.logger debug:@"Destroying interstitial"];

    if (self.interstitial) {
        self.interstitial.delegate = nil;
        self.interstitial = nil;
    }

    self.delegate = nil;
    _isLoading = NO;
}

#pragma mark - FBInterstitialAdDelegate

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
    [self.logger info:@"Interstitial loaded"];
    _isLoading = NO;

    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Interstitial load failed: %@", error.localizedDescription]];
    CLXError *clxError = [CLXMetaErrorHandler toCloudXError:error];
    _isLoading = NO;

    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:self error:clxError];
    }
}

- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
    [self.logger info:@"Interstitial closed"];

    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd {
}

- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
    [self.logger info:@"Interstitial impression"];

    if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
        [self.delegate didShowWithInterstitial:self];
    }

    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
    [self.logger info:@"Interstitial clicked"];

    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

@end 

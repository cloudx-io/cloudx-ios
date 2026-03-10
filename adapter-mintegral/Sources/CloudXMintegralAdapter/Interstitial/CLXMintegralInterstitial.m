#import "CLXMintegralInterstitial.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralInterstitial ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, copy) NSString *unitID;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy, nullable) NSString *creativeID;
@property (nonatomic, assign) BOOL playVideoMute;
@property (nonatomic, strong, nullable) MTGNewInterstitialBidAdManager *interstitialBidManager;
@property (nonatomic, strong, nullable) MTGNewInterstitialAdManager *interstitialManager;
@end

@implementation CLXMintegralInterstitial

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                     playVideoMute:(BOOL)playVideoMute
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _adUnitName = [adUnitName copy];
        _unitID = [unitID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMintegralInitializer sdkVersion];
        _network = @"mintegral";
        _playVideoMute = playVideoMute;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralInterstitial"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@, PlacementID:%@, UnitID:%@, Bidding:%@",
                           adUnitName ?: @"(unknown)", placementID, unitID, bidPayload.length > 0 ? @"YES" : @"NO"]];
    }
    return self;
}

- (void)load {
    // Validate unitID at load time
    if (!_unitID || _unitID.length == 0) {
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Mintegral unit ID is empty%@. "
                                  "Make sure to configure the Mintegral unit ID in your CloudX dashboard under Ad Unit Settings > Mintegral.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];

        id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
        if (delegate && [delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            [delegate didFailToLoadWithInterstitial:self error:error];
        }
        return;
    }

    [self.logger debug:[NSString stringWithFormat:@"Loading interstitial - Placement: %@, PlacementID:%@, UnitID:%@", _adUnitName ?: @"(unknown)", _placementID, _unitID]];

    if (self.bidPayload && self.bidPayload.length > 0) {
        if (!self.interstitialBidManager) {
            self.interstitialBidManager = [[MTGNewInterstitialBidAdManager alloc] initWithPlacementId:self.placementID
                                                                                              unitId:self.unitID
                                                                                            delegate:self];
        }
        self.interstitialBidManager.playVideoMute = self.playVideoMute;
        [self.interstitialBidManager loadAdWithBidToken:self.bidPayload];
    } else {
        if (!self.interstitialManager) {
            self.interstitialManager = [[MTGNewInterstitialAdManager alloc] initWithPlacementId:self.placementID
                                                                                        unitId:self.unitID
                                                                                      delegate:self];
        }
        self.interstitialManager.playVideoMute = self.playVideoMute;

        if ([self.interstitialManager isAdReady]) {
            _creativeID = [self.interstitialManager getCreativeIdWithUnitId:self.unitID];
            [self.delegate didLoadWithInterstitial:self];
            return;
        }

        [self.interstitialManager loadAd];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL bidReady = self.interstitialBidManager && [self.interstitialBidManager isAdReady];
    BOOL waterfallReady = self.interstitialManager && [self.interstitialManager isAdReady];

    if (bidReady) {
        [self.logger info:@"Showing interstitial (bidding)"];
        [self.interstitialBidManager showFromViewController:viewController];
    } else if (waterfallReady) {
        [self.logger info:@"Showing interstitial (waterfall)"];
        [self.interstitialManager showFromViewController:viewController];
    } else {
        [self.logger error:@"Cannot show - ad not ready"];

        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterAdNotReady
                                     description:@"Interstitial not ready"];
        [self.delegate didFailToShowWithInterstitial:self error:error];
    }
}

#pragma mark - MTGNewInterstitialBidAdDelegate

- (void)newInterstitialBidAdLoadSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"Ad load success (waiting for resources)"];
}

- (void)newInterstitialBidAdResourceLoadSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger info:@"Interstitial loaded successfully (bidding)"];
    _creativeID = [adManager getCreativeIdWithUnitId:adManager.currentUnitId];
    [self.delegate didLoadWithInterstitial:self];
}

- (void)newInterstitialBidAdLoadFail:(nonnull NSError *)error adManager:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    CLXError *mappedError = [CLXMintegralErrorHandler toCloudXError:error];
    [self.delegate didFailToLoadWithInterstitial:self error:mappedError];
}

- (void)newInterstitialBidAdShowSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger info:@"Interstitial displayed"];
    [self.delegate didShowWithInterstitial:self];
    [self.delegate impressionWithInterstitial:self];
}

- (void)newInterstitialBidAdShowFail:(nonnull NSError *)error adManager:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    CLXError *mappedError = [CLXMintegralErrorHandler toCloudXError:error];
    [self.delegate didFailToShowWithInterstitial:self error:mappedError];
}

- (void)newInterstitialBidAdClicked:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger info:@"Interstitial clicked"];
    [self.delegate clickWithInterstitial:self];
}

- (void)newInterstitialBidAdDismissedWithConverted:(BOOL)converted adManager:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger info:@"Interstitial hidden"];
    [self.delegate didCloseWithInterstitial:self];
}

- (void)newInterstitialBidAdDidClosed:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"Video completed"];
}

- (void)newInterstitialBidAdPlayCompleted:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"Video play completed"];
}

- (void)newInterstitialBidAdEndCardShowSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"End card shown"];
}

#pragma mark - MTGNewInterstitialAdDelegate (Waterfall)

- (void)newInterstitialAdLoadSuccess:(MTGNewInterstitialAdManager *)adManager {
    [self.logger debug:@"Ad load success - waterfall (waiting for resources)"];
}

- (void)newInterstitialAdResourceLoadSuccess:(MTGNewInterstitialAdManager *)adManager {
    [self.logger info:@"Interstitial loaded successfully (waterfall)"];
    _creativeID = [adManager getCreativeIdWithUnitId:adManager.currentUnitId];
    [self.delegate didLoadWithInterstitial:self];
}

- (void)newInterstitialAdLoadFail:(nonnull NSError *)error adManager:(MTGNewInterstitialAdManager *)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to load (waterfall): %@", error.localizedDescription]];
    CLXError *mappedError = [CLXMintegralErrorHandler toCloudXError:error];
    [self.delegate didFailToLoadWithInterstitial:self error:mappedError];
}

- (void)newInterstitialAdShowSuccess:(MTGNewInterstitialAdManager *)adManager {
    [self.logger info:@"Interstitial displayed (waterfall)"];
    [self.delegate didShowWithInterstitial:self];
    [self.delegate impressionWithInterstitial:self];
}

- (void)newInterstitialAdShowFail:(nonnull NSError *)error adManager:(MTGNewInterstitialAdManager *)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to show (waterfall): %@", error.localizedDescription]];
    CLXError *mappedError = [CLXMintegralErrorHandler toCloudXError:error];
    [self.delegate didFailToShowWithInterstitial:self error:mappedError];
}

- (void)newInterstitialAdClicked:(MTGNewInterstitialAdManager *)adManager {
    [self.logger info:@"Interstitial clicked (waterfall)"];
    [self.delegate clickWithInterstitial:self];
}

- (void)newInterstitialAdDismissedWithConverted:(BOOL)converted adManager:(MTGNewInterstitialAdManager *)adManager {
    [self.logger info:@"Interstitial hidden (waterfall)"];
    [self.delegate didCloseWithInterstitial:self];
}

- (void)newInterstitialAdDidClosed:(MTGNewInterstitialAdManager *)adManager {
    [self.logger debug:@"Video completed (waterfall)"];
}

- (void)newInterstitialAdPlayCompleted:(MTGNewInterstitialAdManager *)adManager {
    [self.logger debug:@"Video play completed (waterfall)"];
}

- (void)newInterstitialAdEndCardShowSuccess:(MTGNewInterstitialAdManager *)adManager {
    [self.logger debug:@"End card shown (waterfall)"];
}

#pragma mark - Lifecycle

- (void)destroy {
    [self.logger debug:@"Destroying interstitial adapter"];
    self.interstitialBidManager = nil;
    self.interstitialManager = nil;
    self.delegate = nil;
}

@end

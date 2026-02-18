//
//  CLXVungleInterstitial.m
//  CloudXVungleAdapter
//

#import "CLXVungleInterstitial.h"
#import "CLXVungleErrorHandler.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleInterstitial ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy, readwrite) NSString *bidID;
@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, copy, readwrite, nullable) NSString *adUnitName;
@property (nonatomic, strong, nullable) VungleInterstitial *interstitial;
@end

@implementation CLXVungleInterstitial

#pragma mark - Initialization

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(nullable id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _adUnitName = [adUnitName copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXVungleInterstitial"];

        [_logger debug:[NSString stringWithFormat:@"Initialized Vungle interstitial - Placement: %@ (%@), BidID: %@, HasBidPayload: %@",
                          adUnitName ?: @"(unknown)", placementID ?: @"(nil)", bidID, bidPayload ? @"YES" : @"NO"]];
    }
    return self;
}

#pragma mark - Public Properties

- (NSString *)sdkVersion {
    return [VungleAds sdkVersion] ?: @"unknown";
}

- (NSString *)network {
    return @"Vungle";
}

#pragma mark - CLXAdapterInterstitial Protocol

- (void)load {
    if (!self.placementID || self.placementID.length == 0) {
        NSString *adUnitContext = self.adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", self.adUnitName] : @"";
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:[NSString stringWithFormat:@"Vungle placement ID is empty%@", adUnitContext]];
        [self.logger error:error.localizedDescription];
        [self handleLoadFailure:error];
        return;
    }

    if (![VungleAds isInitialized]) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterNotInitialized
                                     description:@"Vungle SDK not initialized"];
        [self handleLoadFailure:error];
        return;
    }

    [self.logger info:[NSString stringWithFormat:@"Loading interstitial for placement: %@", self.placementID]];

    self.interstitial = [[VungleInterstitial alloc] initWithPlacementId:self.placementID];
    self.interstitial.delegate = self;
    [self.interstitial load:self.bidPayload];
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (![self.interstitial canPlayAd]) {
        [self.logger error:@"Interstitial ad not ready to show"];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterAdNotReady
                                     description:@"Interstitial ad is not loaded or ready to play"];
        CLXError *clxError = [CLXVungleErrorHandler toCloudXError:error isShowError:YES];
        id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
        if (delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate didFailToShowWithInterstitial:self error:clxError];
            });
        }
        return;
    }

    [self.logger info:@"Showing interstitial ad"];
    [self.interstitial presentWith:viewController];
}

- (void)destroy {
    [self.logger debug:@"Destroying interstitial adapter"];
    if (self.interstitial) {
        self.interstitial.delegate = nil;
        self.interstitial = nil;
    }
    self.delegate = nil;
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(VungleInterstitial *)interstitial {
    [self.logger info:@"Interstitial ad loaded successfully"];

    [self.delegate didLoadWithInterstitial:self];
}

- (void)interstitialAdDidFailToLoad:(VungleInterstitial *)interstitial withError:(NSError *)error {
    [self handleLoadFailure:error];
}

- (void)interstitialAdWillPresent:(VungleInterstitial *)interstitial {
    [self.logger debug:@"Interstitial ad will present"];
}

- (void)interstitialAdDidPresent:(VungleInterstitial *)interstitial {
    [self.logger info:@"Interstitial ad presented successfully"];
    // Note: didShow fires in didTrackImpression
}

- (void)interstitialAdDidFailToPresent:(VungleInterstitial *)interstitial withError:(NSError *)error {
    [self handleShowFailure:error];
}

- (void)interstitialAdDidTrackImpression:(VungleInterstitial *)interstitial {
    [self.logger info:@"Interstitial ad impression tracked"];

    // Fire show then impression together
    [self.delegate didShowWithInterstitial:self];
    [self.delegate impressionWithInterstitial:self];
}

- (void)interstitialAdDidClick:(VungleInterstitial *)interstitial {
    [self.logger info:@"Interstitial ad clicked"];

    [self.delegate clickWithInterstitial:self];
}

- (void)interstitialAdWillLeaveApplication:(VungleInterstitial *)interstitial {
    [self.logger debug:@"Interstitial ad will leave application"];
}

- (void)interstitialAdWillClose:(VungleInterstitial *)interstitial {
    [self.logger debug:@"Interstitial ad will close"];
}

- (void)interstitialAdDidClose:(VungleInterstitial *)interstitial {
    [self.logger info:@"Interstitial ad closed"];

    [self.delegate didCloseWithInterstitial:self];
}

#pragma mark - Private Methods

- (void)handleLoadFailure:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Interstitial load failed for placement %@: %@", self.placementID, error.localizedDescription]];
    CLXError *clxError = [CLXVungleErrorHandler toCloudXError:error isShowError:NO];
    id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
    if (delegate) {
        [delegate didFailToLoadWithInterstitial:self error:clxError];
    }
}

- (void)handleShowFailure:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Interstitial show failed for placement %@: %@", self.placementID, error.localizedDescription]];
    CLXError *clxError = [CLXVungleErrorHandler toCloudXError:error isShowError:YES];
    id<CLXAdapterInterstitialDelegate> delegate = self.delegate;
    if (delegate) {
        [delegate didFailToShowWithInterstitial:self error:clxError];
    }
}

@end

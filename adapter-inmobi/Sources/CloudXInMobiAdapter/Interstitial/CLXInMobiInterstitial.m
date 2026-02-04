//
//  CLXInMobiInterstitial.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInterstitial.h>)
#import <CloudXInMobiAdapter/CLXInMobiInterstitial.h>
#else
#import "CLXInMobiInterstitial.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXInMobiAdapter/CLXInMobiErrorHandler.h>
#else
#import "../Utils/CLXInMobiErrorHandler.h"
#endif

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInitializer.h>)
#import <CloudXInMobiAdapter/CLXInMobiInitializer.h>
#else
#import "../Initializers/CLXInMobiInitializer.h"
#endif

@interface CLXInMobiInterstitial () {
    NSString *_bidID;
}
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) long long placementID;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@end

@implementation CLXInMobiInterstitial

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;  // May be 0 (invalid) - validation in load()
        _adUnitName = [adUnitName copy];  // For error messages
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXInMobiInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiInterstitial"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%lld%@), BidID: %@, HasBidPayload: %@", 
                           adUnitName ?: @"(unknown)", placementID, (placementID == 0 ? @" - invalid" : @""), bidID, bidPayload ? @"YES" : @"NO"]];
        
        // Only create interstitial if placementID is valid
        // Otherwise defer to load() for validation
        if (placementID != 0) {
            _interstitial = [[IMInterstitial alloc] initWithPlacementId:placementID];
            _interstitial.delegate = self;
        }
    }
    return self;
}

- (NSString *)bidID {
    [self.logger debug:[NSString stringWithFormat:@"bidID getter called - returning: %@", _bidID]];
    return _bidID;
}

- (NSString *)network {
    return @"inmobi";
}

- (BOOL)isReady {
    BOOL ready = _interstitial && [_interstitial isReady];
    [self.logger debug:[NSString stringWithFormat:@"isReady: %@", ready ? @"YES" : @"NO"]];
    return ready;
}

- (void)load {
    // Validate placement ID at load time (deferred validation pattern)
    if (_placementID == 0) {
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"InMobi placement ID is empty%@. "
                                  "Make sure to configure the InMobi placement ID in your CloudX dashboard under Ad Unit Settings > InMobi.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
            [self.delegate didFailToLoadWithInterstitial:self error:error];
        }
        return;
    }
    
    // Create interstitial now if not already created (deferred from init)
    if (!_interstitial) {
        _interstitial = [[IMInterstitial alloc] initWithPlacementId:_placementID];
        _interstitial.delegate = self;
        [self.logger debug:@"Created interstitial with validated placement ID"];
    }
    
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading ad - Placement: %lld, HasBidPayload: %@", 
                       _placementID, self.bidPayload ? @"YES" : @"NO"]];
    
    // Ensure InMobi SDK calls happen on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.interstitial setExtras:[CLXInMobiInitializer extras]];
        if (self.bidPayload) {
            [self.interstitial load:self.bidPayload];
        } else {
            [self.interstitial load];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = [self isReady];
    
    if (ready) {
        [self.logger info:@"Showing interstitial ad"];
        
        // Call didShowWithInterstitial before showing the ad
        if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
            [self.delegate didShowWithInterstitial:self];
        }
        
        [_interstitial showFrom:viewController];
    } else {
        [self.logger error:@"Cannot show ad - not ready"];
        
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdNotReady 
                                         description:@"Cannot show interstitial - ad not ready"];
        
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
            [self.delegate didFailToShowWithInterstitial:self error:showError];
        }
    }
}

- (void)destroy {
    [self.logger debug:@"Destroying interstitial"];
    
    if (self.interstitial) {
        self.interstitial.delegate = nil;
        self.interstitial = nil;
    }
    
    self.delegate = nil;
    _isLoading = NO;
    
    [self.logger debug:@"Destruction complete"];
}

#pragma mark - IMInterstitialDelegate

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    [self.logger info:[NSString stringWithFormat:@"Loaded successfully - Ready: %@", [interstitial isReady] ? @"YES" : @"NO"]];
    
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    
    _isLoading = NO;
    
    NSError *clxError = [CLXInMobiErrorHandler handleInMobiError:[NSError errorWithDomain:@"InMobi" code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]
                                                      withLogger:self.logger
                                                         context:@"Interstitial Load"
                                                     placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:self error:clxError];
    }
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
    [self.logger info:@"Interstitial presented"];
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *clxError = [CLXInMobiErrorHandler handleInMobiError:[NSError errorWithDomain:@"InMobi" code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]
                                                      withLogger:self.logger
                                                         context:@"Interstitial Show"
                                                     placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:self error:clxError];
    }
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
    [self.logger debug:@"Interstitial will present"];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [self.logger info:@"Interstitial dismissed"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
    [self.logger debug:@"Interstitial will dismiss"];
}

- (void)interstitialAdImpressed:(IMInterstitial *)interstitial {
    // Native SDK impression callback - fires when ad is actually displayed/rendered
    [self.logger info:@"Interstitial impression tracked by ad network SDK"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(nullable NSDictionary *)params {
    [self.logger info:@"Interstitial clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
    [self.logger debug:@"User will leave application"];
}

#pragma mark - Additional SDK callbacks (logging only - no delegate action)

- (void)interstitial:(IMInterstitial *)interstitial rewardActionCompletedWithRewards:(NSDictionary *)rewards {
    // NO-OP: Rewards are not supported in the interstitial ad format.
    // If the ad network sends rewards for interstitials, we log but do not propagate.
    // Use the Rewarded ad format for reward-based ads.
    [self.logger warn:[NSString stringWithFormat:@"Unexpected reward on interstitial ad (not supported): %@", rewards]];
}

- (void)interstitialDidReceiveAd:(IMInterstitial *)interstitial {
    // NO-OP: Ad content received before load completes. Logged for diagnostics only.
    // Our SDK fires didLoadWithInterstitial: when the ad is fully ready.
    [self.logger debug:@"Interstitial did receive ad content"];
}

@end


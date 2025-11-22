//
//  CLXInMobiRewarded.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiRewarded.h>)
#import <CloudXInMobiAdapter/CLXInMobiRewarded.h>
#else
#import "CLXInMobiRewarded.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXInMobiAdapter/CLXInMobiErrorHandler.h>
#else
#import "../Utils/CLXInMobiErrorHandler.h"
#endif

@interface CLXInMobiRewarded () {
    NSString *_bidID;
}
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) long long placementID;
@end

@implementation CLXInMobiRewarded

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;  // May be 0 (invalid) - validation in load()
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = @"10.8.8";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiRewarded"];
        _timeoutInterval = 30.0;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %lld%@, BidID: %@", 
                           placementID, (placementID == 0 ? @" (invalid)" : @""), bidID]];
        
        // Only create rewarded if placementID is valid
        // Otherwise defer to load() for validation
        if (placementID != 0) {
            _interstitial = [[IMInterstitial alloc] initWithPlacementId:placementID];
            _interstitial.delegate = self;
        }
    }
    return self;
}

- (NSString *)bidID {
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
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                     description:@"[InMobi] Invalid or missing placement ID for rewarded ad"];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            [self.delegate didFailToLoadWithRewarded:self error:error];
        }
        return;
    }
    
    // Create rewarded now if not already created (deferred from init)
    if (!_interstitial) {
        _interstitial = [[IMInterstitial alloc] initWithPlacementId:_placementID];
        _interstitial.delegate = self;
        [self.logger debug:@"Created rewarded with validated placement ID"];
    }
    
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading rewarded - Placement: %lld", _placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.interstitial load:self.bidPayload];
        } else {
            [self.interstitial load];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = [self isReady];
    
    if (ready) {
        [self.logger info:@"Showing rewarded ad"];
        
        if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
            [self.delegate didShowWithRewarded:self];
        }
        
        [_interstitial showFrom:viewController];
    } else {
        [self.logger error:@"Cannot show ad - not ready"];
        
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdNotReady 
                                         description:@"Cannot show rewarded - ad not ready"];
        
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
            [self.delegate didFailToShowWithRewarded:self error:showError];
        }
    }
}

- (void)destroy {
    [self.logger debug:@"Destroying rewarded"];
    
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
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:self];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *clxError = [CLXInMobiErrorHandler handleInMobiError:[NSError errorWithDomain:@"InMobi" code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]
                                                      withLogger:self.logger
                                                         context:@"Rewarded Load"
                                                     placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
        [self.delegate didFailToLoadWithRewarded:self error:clxError];
    }
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
    [self.logger info:@"Rewarded presented"];
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *clxError = [CLXInMobiErrorHandler handleInMobiError:[NSError errorWithDomain:@"InMobi" code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]
                                                      withLogger:self.logger
                                                         context:@"Rewarded Show"
                                                     placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        [self.delegate didFailToShowWithRewarded:self error:clxError];
    }
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
    [self.logger debug:@"Rewarded will present"];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [self.logger info:@"Rewarded dismissed"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
    }
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
    [self.logger debug:@"Rewarded will dismiss"];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(nullable NSDictionary *)params {
    [self.logger info:@"Rewarded clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

- (void)interstitial:(IMInterstitial *)interstitial rewardActionCompletedWithRewards:(NSDictionary *)rewards {
    [self.logger info:[NSString stringWithFormat:@"✅ Reward earned: %@", rewards]];
    
    if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
        [self.delegate userRewardWithRewarded:self];
    }
}

- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
    [self.logger debug:@"User will leave application"];
}

@end


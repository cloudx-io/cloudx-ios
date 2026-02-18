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

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInitializer.h>)
#import <CloudXInMobiAdapter/CLXInMobiInitializer.h>
#else
#import "../Initializers/CLXInMobiInitializer.h"
#endif

@interface CLXInMobiRewarded () {
    NSString *_bidID;
}
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, nullable) IMInterstitial *interstitial;
@property (nonatomic, strong, nullable) NSData *bidPayload;
@property (nonatomic, assign) long long placementID;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, assign) BOOL hasGrantedReward;
@end

@implementation CLXInMobiRewarded

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;  // May be 0 (invalid) - validation in load()
        _adUnitName = [adUnitName copy];  // For error messages
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXInMobiInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiRewarded"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%lld%@), BidID: %@",
                           adUnitName ?: @"(unknown)", placementID, (placementID == 0 ? @" - invalid" : @""), bidID]];
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
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"InMobi placement ID is empty%@. "
                                  "Make sure to configure the InMobi placement ID in your CloudX dashboard under Ad Unit Settings > InMobi.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];

        id<CLXAdapterRewardedDelegate> delegate = self.delegate;
        if (delegate) {
            [delegate didFailToLoadWithRewarded:self error:error];
        }
        return;
    }
    
    if (!_interstitial) {
        _interstitial = [[IMInterstitial alloc] initWithPlacementId:_placementID];
        _interstitial.delegate = self;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Loading rewarded - Placement: %lld", _placementID]];

    [self.interstitial setExtras:[CLXInMobiInitializer extras]];
    if (self.bidPayload) {
        [self.interstitial load:self.bidPayload];
    } else {
        [self.interstitial load];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = [self isReady];

    if (ready) {
        [self.logger info:@"Showing rewarded ad"];

        // Reset reward state for new show
        self.hasGrantedReward = NO;

        [_interstitial showFrom:viewController];
    } else {
        [self.logger error:@"Cannot show ad - not ready"];

        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdapterAdNotReady
                                         description:@"Cannot show rewarded - ad not ready"];
        CLXError *clxError = [CLXInMobiErrorHandler toCloudXError:showError];
        id<CLXAdapterRewardedDelegate> delegate = self.delegate;
        if (delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate didFailToShowWithRewarded:self error:clxError];
            });
        }
    }
}

#pragma mark - IMInterstitialDelegate

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
    [self.logger info:[NSString stringWithFormat:@"Loaded successfully - Ready: %@", [interstitial isReady] ? @"YES" : @"NO"]];

    [self.delegate didLoadWithRewarded:self];
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToLoadWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];

    CLXError *clxError = [CLXInMobiErrorHandler toCloudXError:error];
    [self.delegate didFailToLoadWithRewarded:self error:clxError];
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
    [self.logger info:@"Rewarded presented"];
}

- (void)interstitial:(IMInterstitial *)interstitial didFailToPresentWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    CLXError *clxError = [CLXInMobiErrorHandler toCloudXError:error];
    [self.delegate didFailToShowWithRewarded:self error:clxError];
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
    [self.logger debug:@"Rewarded will present"];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
    [self.logger info:@"Rewarded dismissed"];

    // Grant reward on close if user completed the reward action
    if (self.hasGrantedReward) {
        [self.logger info:@"Granting reward to user"];
        [self.delegate userRewardWithRewarded:self];
    }

    [self.delegate didCloseWithRewarded:self];
}

- (void)interstitialAdImpressed:(IMInterstitial *)interstitial {
    // Native SDK impression callback - fires when ad is actually displayed/rendered
    [self.logger info:@"Rewarded impression tracked"];

    // Fire show callback on impression (when ad is actually visible)
    [self.delegate didShowWithRewarded:self];
    [self.delegate impressionWithRewarded:self];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(nullable NSDictionary *)params {
    [self.logger info:@"Rewarded clicked"];
    
    [self.delegate clickWithRewarded:self];
}

- (void)interstitial:(IMInterstitial *)interstitial rewardActionCompletedWithRewards:(NSDictionary *)rewards {
    [self.logger info:[NSString stringWithFormat:@"Reward action completed: %@", rewards]];

    self.hasGrantedReward = YES;
}

- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
    [self.logger debug:@"User will leave application"];
}

#pragma mark - Additional SDK callbacks (logging only - no delegate action)

- (void)interstitial:(IMInterstitial *)interstitial didReceiveWithMetaInfo:(IMAdMetaInfo *)metaInfo {
    [self.logger debug:@"Rewarded request succeeded"];
}

@end


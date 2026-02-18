//
//  CLXVungleRewarded.m
//  CloudXVungleAdapter
//

#import "CLXVungleRewarded.h"
#import "CLXVungleErrorHandler.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleRewarded ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy, readwrite) NSString *bidID;
@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, copy, readwrite, nullable) NSString *adUnitName;
@property (nonatomic, strong, nullable) VungleRewarded *rewarded;
@property (nonatomic, assign) BOOL grantedReward;
@end

@implementation CLXVungleRewarded

#pragma mark - Initialization

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(nullable id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _adUnitName = [adUnitName copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXVungleRewarded"];
        _grantedReward = NO;

        [_logger debug:[NSString stringWithFormat:@"Initialized Vungle rewarded - Placement: %@ (%@), BidID: %@, HasBidPayload: %@",
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

#pragma mark - CLXAdapterRewarded Protocol

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

    [self.logger info:[NSString stringWithFormat:@"Loading rewarded ad for placement: %@", self.placementID]];

    self.rewarded = [[VungleRewarded alloc] initWithPlacementId:self.placementID];
    self.rewarded.delegate = self;
    [self.rewarded load:self.bidPayload];
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (![self.rewarded canPlayAd]) {
        [self.logger error:@"Rewarded ad not ready to show"];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterAdNotReady
                                     description:@"Rewarded ad is not loaded or ready to play"];
        CLXError *clxError = [CLXVungleErrorHandler toCloudXError:error isShowError:YES];
        id<CLXAdapterRewardedDelegate> delegate = self.delegate;
        if (delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate didFailToShowWithRewarded:self error:clxError];
            });
        }
        return;
    }

    [self.logger info:@"Showing rewarded ad"];
    self.grantedReward = NO;
    [self.rewarded presentWith:viewController];
}

- (void)destroy {
    [self.logger debug:@"Destroying rewarded adapter"];
    if (self.rewarded) {
        self.rewarded.delegate = nil;
        self.rewarded = nil;
    }
    self.delegate = nil;
    self.grantedReward = NO;
}

#pragma mark - VungleRewardedDelegate

- (void)rewardedAdDidLoad:(VungleRewarded *)rewarded {
    [self.logger info:@"Rewarded ad loaded successfully"];

    [self.delegate didLoadWithRewarded:self];
}

- (void)rewardedAdDidFailToLoad:(VungleRewarded *)rewarded withError:(NSError *)error {
    [self handleLoadFailure:error];
}

- (void)rewardedAdWillPresent:(VungleRewarded *)rewarded {
    [self.logger debug:@"Rewarded ad will present"];
}

- (void)rewardedAdDidPresent:(VungleRewarded *)rewarded {
    [self.logger info:@"Rewarded ad presented successfully"];
    // Note: didShow fires in didTrackImpression
}

- (void)rewardedAdDidFailToPresent:(VungleRewarded *)rewarded withError:(NSError *)error {
    [self handleShowFailure:error];
}

- (void)rewardedAdDidTrackImpression:(VungleRewarded *)rewarded {
    [self.logger info:@"Rewarded ad impression tracked"];

    // Fire show then impression together
    [self.delegate didShowWithRewarded:self];
    [self.delegate impressionWithRewarded:self];
}

- (void)rewardedAdDidClick:(VungleRewarded *)rewarded {
    [self.logger info:@"Rewarded ad clicked"];

    [self.delegate clickWithRewarded:self];
}

- (void)rewardedAdWillLeaveApplication:(VungleRewarded *)rewarded {
    [self.logger debug:@"Rewarded ad will leave application"];
}

- (void)rewardedAdDidRewardUser:(VungleRewarded *)rewarded {
    [self.logger info:@"User earned reward from rewarded ad"];
    self.grantedReward = YES;
    // Note: Reward is granted in didClose callback
}

- (void)rewardedAdWillClose:(VungleRewarded *)rewarded {
    [self.logger debug:@"Rewarded ad will close"];
}

- (void)rewardedAdDidClose:(VungleRewarded *)rewarded {
    [self.logger info:[NSString stringWithFormat:@"Rewarded ad closed - User rewarded: %@", self.grantedReward ? @"YES" : @"NO"]];

    // Grant reward in close callback
    if (self.grantedReward) {
        [self.delegate userRewardWithRewarded:self];
    }

    [self.delegate didCloseWithRewarded:self];
}

#pragma mark - Private Methods

- (void)handleLoadFailure:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Rewarded load failed for placement %@: %@", self.placementID, error.localizedDescription]];
    CLXError *clxError = [CLXVungleErrorHandler toCloudXError:error isShowError:NO];
    id<CLXAdapterRewardedDelegate> delegate = self.delegate;
    if (delegate) {
        [delegate didFailToLoadWithRewarded:self error:clxError];
    }
}

- (void)handleShowFailure:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Rewarded show failed for placement %@: %@", self.placementID, error.localizedDescription]];
    CLXError *clxError = [CLXVungleErrorHandler toCloudXError:error isShowError:YES];
    id<CLXAdapterRewardedDelegate> delegate = self.delegate;
    if (delegate) {
        [delegate didFailToShowWithRewarded:self error:clxError];
    }
}

@end

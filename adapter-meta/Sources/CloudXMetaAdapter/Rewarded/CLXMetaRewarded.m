//
//  CLXMetaRewarded.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaRewarded.h>)
#import <CloudXMetaAdapter/CLXMetaRewarded.h>
#else
#import "CLXMetaRewarded.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaErrorHandler.h>)
#import <CloudXMetaAdapter/CLXMetaErrorHandler.h>
#else
#import "CLXMetaErrorHandler.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

@interface CLXMetaRewarded ()

@property (nonatomic, strong) FBRewardedVideoAd *rewarded;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *placementName;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL grantedReward;

@end

@implementation CLXMetaRewarded

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _placementName = [placementName copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = FB_AD_SDK_VERSION;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaRewarded"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%@), BidID: %@",
                           placementName ?: @"(unknown)", placementID ?: @"(nil)", bidID]];

        if (placementID && placementID.length > 0) {
            _rewarded = [[FBRewardedVideoAd alloc] initWithPlacementID:placementID];
            _rewarded.delegate = self;
        }
    }
    return self;
}

- (NSString *)network {
    return @"meta";
}

- (BOOL)isReady {
    BOOL ready = _rewarded && _rewarded.isAdValid;
    return ready;
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

        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            [self.delegate didFailToLoadWithRewarded:self error:error];
        }
        return;
    }

    if (!_rewarded) {
        _rewarded = [[FBRewardedVideoAd alloc] initWithPlacementID:_placementID];
        _rewarded.delegate = self;
    }

    if (_isLoading) {
        return;
    }

    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading rewarded - Placement: %@", _placementID]];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (strongSelf.bidPayload) {
            [strongSelf.rewarded loadAdWithBidPayload:strongSelf.bidPayload];
        } else {
            [strongSelf.rewarded loadAd];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (void)setRewardDataWithUserID:(NSString *)userID withCurrency:(NSString *)currency {
    if (_rewarded) {
        [_rewarded setRewardDataWithUserID:userID withCurrency:currency];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (![self isReady]) {
        [self.logger error:@"Unable to show rewarded - ad is not valid, marking as expired"];
        NSError *showError = [CLXError errorWithCode:CLXErrorCodeAdapterAdExpired
                                         description:@"Ad expired"];
        [self.delegate didFailToShowWithRewarded:self error:showError];
        return;
    }

    [self.logger info:@"Showing rewarded"];
    [_rewarded showAdFromRootViewController:viewController];
}

- (void)destroy {
    [self.logger debug:@"Destroying rewarded"];

    if (self.rewarded) {
        self.rewarded.delegate = nil;
        self.rewarded = nil;
    }

    self.delegate = nil;
    _isLoading = NO;
}

#pragma mark - FBRewardedVideoAdDelegate

- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"Rewarded video ad loaded"];
    _isLoading = NO;

    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:self];
    }
}

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Rewarded load failed: %@", error.localizedDescription]];
    CLXError *clxError = [CLXMetaErrorHandler toCloudXError:error];
    _isLoading = NO;

    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
        [self.delegate didFailToLoadWithRewarded:self error:clxError];
    }
}

- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"Rewarded clicked"];

    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
}

- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"Rewarded closed"];

    if (self.grantedReward) {
        if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
            [self.delegate userRewardWithRewarded:self];
        }
    }

    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
    }
}

- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"Rewarded will close"];
}

- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"Rewarded video completed"];
    self.grantedReward = YES;
}

- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
    [self.logger info:@"Rewarded impression"];

    if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
        [self.delegate didShowWithRewarded:self];
    }

    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

@end 

//
//  CLXInMobiBanner.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiBanner.h>)
#import <CloudXInMobiAdapter/CLXInMobiBanner.h>
#else
#import "CLXInMobiBanner.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXInMobiAdapter/CLXInMobiErrorHandler.h>
#else
#import "../Utils/CLXInMobiErrorHandler.h"
#endif

@interface CLXInMobiBanner () {
    NSString *_bidID;
}
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) long long placementID;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, assign) CGSize bannerSize;  // Store for deferred creation
@end

@implementation CLXInMobiBanner

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                             bidID:(NSString *)bidID
                              size:(CGSize)size
                    viewController:(UIViewController *)viewController
                          delegate:(id<CLXAdapterBannerDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;  // May be 0 (invalid) - validation in load()
        _bidID = [bidID copy];
        _delegate = delegate;
        _viewController = viewController;
        _bannerSize = size;  // Store for deferred creation
        _sdkVersion = @"10.8.8";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiBanner"];
        _timeoutInterval = 30.0;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %lld%@, BidID: %@, Size: %.0fx%.0f", 
                           placementID, (placementID == 0 ? @" (invalid)" : @""), bidID, size.width, size.height]];
        
        // Only create banner if placementID is valid
        // Otherwise defer to load() for validation
        if (placementID != 0) {
            _banner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) placementId:placementID];
            _banner.delegate = self;
        }
    }
    return self;
}

- (NSString *)bidID {
    return _bidID;
}

- (UIView *)bannerView {
    return self.banner;
}

- (BOOL)clx_isFlexibleSize {
    return NO;
}

- (BOOL)isFlexibleSize {
    return [self clx_isFlexibleSize];
}

- (void)load {
    // Validate placement ID at load time (deferred validation pattern)
    if (_placementID == 0) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeInvalidAdUnitID
                                     description:@"[InMobi] Invalid or missing placement ID for banner ad"];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    // Create banner now if not already created (deferred from init)
    if (!_banner) {
        _banner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, _bannerSize.width, _bannerSize.height) 
                                      placementId:_placementID];
        _banner.delegate = self;
        [self.logger debug:@"Created banner with validated placement ID"];
    }
    
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading banner - Placement: %lld", _placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.banner load:self.bidPayload];
        } else {
            [self.banner load];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    // NO-OP: Impressions are tracked via bannerAdImpressed: callback from the ad network SDK.
    // This method is called by the core SDK but is not needed for this adapter.
    [self.logger debug:@"showFromViewController called (no-op for this adapter)"];
}

- (void)destroy {
    [self.logger debug:@"Destroying banner"];
    
    if (self.banner) {
        self.banner.delegate = nil;
        self.banner = nil;
    }
    
    self.delegate = nil;
    _isLoading = NO;
    
    [self.logger debug:@"Destruction complete"];
}

#pragma mark - IMBannerDelegate

- (void)bannerDidFinishLoading:(IMBanner *)banner {
    [self.logger info:@"Banner loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    }
}

- (void)bannerAdImpressed:(IMBanner *)banner {
    // Native SDK impression callback - fires when ad is actually displayed/rendered
    [self.logger info:@"Banner impression tracked by ad network SDK"];
    
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

- (void)banner:(IMBanner *)banner didFailToLoadWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *clxError = [CLXInMobiErrorHandler handleInMobiError:[NSError errorWithDomain:@"InMobi" code:error.code userInfo:@{NSLocalizedDescriptionKey: error.localizedDescription}]
                                                      withLogger:self.logger
                                                         context:@"Banner Load"
                                                     placementID:@(_placementID).stringValue];
    
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:clxError];
    }
}

- (void)banner:(IMBanner *)banner didInteractWithParams:(nullable NSDictionary *)params {
    [self.logger info:@"Banner clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)userWillLeaveApplicationFromBanner:(IMBanner *)banner {
    [self.logger debug:@"User will leave application"];
}

- (void)bannerWillPresentScreen:(IMBanner *)banner {
    [self.logger debug:@"Banner will present screen"];
    if ([self.delegate respondsToSelector:@selector(didExpandBanner:)]) {
        [self.delegate didExpandBanner:self];
    }
}

- (void)bannerDidPresentScreen:(IMBanner *)banner {
    [self.logger debug:@"Banner did present screen"];
}

- (void)bannerWillDismissScreen:(IMBanner *)banner {
    [self.logger debug:@"Banner will dismiss screen"];
}

- (void)bannerDidDismissScreen:(IMBanner *)banner {
    [self.logger debug:@"Banner did dismiss screen"];
    if ([self.delegate respondsToSelector:@selector(didCollapseBanner:)]) {
        [self.delegate didCollapseBanner:self];
    }
}

#pragma mark - Additional SDK callbacks (logging only - no delegate action)

- (void)banner:(IMBanner *)banner didReceiveWithMetaInfo:(IMAdMetaInfo *)metaInfo {
    // NO-OP: Metadata received before load completes. Logged for diagnostics only.
    // Our SDK fires didLoadBanner: when the ad is fully ready, not on metadata receipt.
    [self.logger debug:[NSString stringWithFormat:@"Banner received meta info - bidValue: %@", metaInfo.bidInfo]];
}

- (void)banner:(IMBanner *)banner rewardActionCompletedWithRewards:(NSDictionary *)rewards {
    // NO-OP: Rewarded banners are not supported in our banner ad format.
    // If the ad network sends rewards for banners, we log but do not propagate.
    // Use the Rewarded ad format for reward-based ads.
    [self.logger warn:[NSString stringWithFormat:@"Unexpected reward on banner ad (not supported): %@", rewards]];
}

@end


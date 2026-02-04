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

#if __has_include(<CloudXInMobiAdapter/CLXInMobiInitializer.h>)
#import <CloudXInMobiAdapter/CLXInMobiInitializer.h>
#else
#import "../Initializers/CLXInMobiInitializer.h"
#endif

@interface CLXInMobiBanner () {
    NSString *_bidID;
}
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) long long placementID;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, assign) CGSize bannerSize;  // Store for deferred creation
@end

@implementation CLXInMobiBanner

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              size:(CGSize)size
                    viewController:(UIViewController *)viewController
                          delegate:(id<CLXAdapterBannerDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = bidPayload;
        _placementID = placementID;  // May be 0 (invalid) - validation in load()
        _adUnitName = [adUnitName copy];  // For error messages
        _bidID = [bidID copy];
        _delegate = delegate;
        _viewController = viewController;
        _bannerSize = size;  // Store for deferred creation
        _sdkVersion = [CLXInMobiInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiBanner"];

        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%lld%@), BidID: %@, Size: %.0fx%.0f",
                           adUnitName ?: @"(unknown)", placementID, (placementID == 0 ? @" - invalid" : @""), bidID, size.width, size.height]];
        
        // Banner creation is deferred to load() to ensure it happens on main thread
        // without using dispatch_sync which can cause deadlocks
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
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"InMobi placement ID is empty%@. "
                                  "Make sure to configure the InMobi placement ID in your CloudX dashboard under Ad Unit Settings > InMobi.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    
    // All UI operations happen on main thread via dispatch_async
    // Using dispatch_async (not sync) to prevent deadlocks when returning from deep links
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        // Create banner if not already created
        if (!strongSelf.banner) {
            CGSize size = strongSelf.bannerSize;
            long long placement = strongSelf.placementID;
            strongSelf.banner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                                    placementId:placement];
            strongSelf.banner.delegate = strongSelf;
            [strongSelf.logger debug:[NSString stringWithFormat:@"Created banner - Placement: %lld", placement]];
        }
        
        [strongSelf.logger debug:[NSString stringWithFormat:@"Loading banner - Placement: %lld", strongSelf.placementID]];
        [strongSelf.banner setExtras:[CLXInMobiInitializer extras]];

        if (strongSelf.bidPayload) {
            [strongSelf.banner load:strongSelf.bidPayload];
        } else {
            [strongSelf.banner load];
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
    
    // Clear delegate and state immediately (thread-safe)
    self.delegate = nil;
    _isLoading = NO;
    
    // IMBanner is a UIView - must be cleaned up on main thread
    IMBanner *bannerToDestroy = self.banner;
    self.banner = nil;
    
    if (bannerToDestroy) {
        if ([NSThread isMainThread]) {
            bannerToDestroy.delegate = nil;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                bannerToDestroy.delegate = nil;
            });
        }
    }
    
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
    [self.logger info:@"👆 Banner clicked"];
    
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


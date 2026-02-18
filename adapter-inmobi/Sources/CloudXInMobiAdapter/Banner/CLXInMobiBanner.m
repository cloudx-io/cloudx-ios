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

@interface CLXInMobiBanner ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, nullable) IMBanner *banner;
@property (nonatomic, strong, nullable) NSData *bidPayload;
@property (nonatomic, assign) long long placementID;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, assign) CGSize bannerSize;
@end

@implementation CLXInMobiBanner

@synthesize timeout = _timeout;

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
        _delegate = delegate;
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

- (UIView *)bannerView {
    return self.banner;
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

        id<CLXAdapterBannerDelegate> delegate = self.delegate;
        if (delegate) {
            [delegate failToLoadBanner:self error:error];
        }
        return;
    }

    // Create banner if not already created (Core SDK guarantees main thread)
    if (!self.banner) {
        self.banner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, _bannerSize.width, _bannerSize.height)
                                          placementId:_placementID];
        self.banner.transitionAnimation = UIViewAnimationTransitionNone;
        [self.banner shouldAutoRefresh:NO];
        self.banner.delegate = self;
        [self.logger debug:[NSString stringWithFormat:@"Created banner - Placement: %lld", _placementID]];
    }

    [self.banner setExtras:[CLXInMobiInitializer extras]];

    [self.logger debug:[NSString stringWithFormat:@"Loading banner - Placement: %lld", _placementID]];
    if (_bidPayload) {
        [self.banner load:_bidPayload];
    } else {
        [self.banner load];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    // NO-OP: Impressions are tracked via bannerAdImpressed: callback from the ad network SDK.
    // This method is called by the core SDK but is not needed for this adapter.
    [self.logger debug:@"showFromViewController called (no-op for this adapter)"];
}

- (void)destroy {
    [self.logger debug:@"Destroying banner"];

    self.delegate = nil;

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
    [self.logger info:@"Banner loaded"];
    [self.delegate didLoadBanner:self];
}

- (void)banner:(IMBanner *)banner didFailToLoadWithError:(IMRequestStatus *)error {
    [self.logger error:[NSString stringWithFormat:@"Banner failed to load: %@", error.localizedDescription]];
    CLXError *clxError = [CLXInMobiErrorHandler toCloudXError:error];
    [self.delegate failToLoadBanner:self error:clxError];
}

- (void)bannerAdImpressed:(IMBanner *)banner {
    [self.logger info:@"Banner impression tracked"];
    [self.delegate didShowBanner:self];
    [self.delegate impressionBanner:self];
}

- (void)banner:(IMBanner *)banner didInteractWithParams:(NSDictionary *)params {
    [self.logger info:@"Banner clicked"];
    [self.delegate clickBanner:self];
}

- (void)bannerDidPresentScreen:(IMBanner *)banner {
    [self.logger debug:@"Banner expanded"];
    if ([self.delegate respondsToSelector:@selector(didExpandBanner:)]) {
        [self.delegate didExpandBanner:self];
    }
}

- (void)bannerDidDismissScreen:(IMBanner *)banner {
    [self.logger debug:@"Banner collapsed"];
    if ([self.delegate respondsToSelector:@selector(didCollapseBanner:)]) {
        [self.delegate didCollapseBanner:self];
    }
}

- (void)userWillLeaveApplicationFromBanner:(IMBanner *)banner {
    [self.logger debug:@"User will leave application"];
}

@end


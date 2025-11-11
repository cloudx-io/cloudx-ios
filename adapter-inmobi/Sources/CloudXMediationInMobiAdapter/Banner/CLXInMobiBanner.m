//
//  CLXInMobiBanner.m
//  CloudXMediationInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiBanner.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiBanner.h>
#else
#import "CLXInMobiBanner.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXMediationInMobiAdapter/CLXInMobiErrorHandler.h>)
#import <CloudXMediationInMobiAdapter/CLXInMobiErrorHandler.h>
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
        _placementID = placementID;
        _bidID = [bidID copy];
        _delegate = delegate;
        _viewController = viewController;
        _sdkVersion = @"10.8.8";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiBanner"];
        _timeoutInterval = 30.0;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID: %lld, BidID: %@, Size: %.0fx%.0f", 
                           placementID, bidID, size.width, size.height]];
        
        _banner = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) placementId:placementID];
        _banner.delegate = self;
    }
    return self;
}

- (NSString *)bidID {
    return _bidID;
}

- (UIView *)bannerView {
    return self.banner;
}

- (void)load {
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
    [self.logger info:@"Banner shown (added to view hierarchy)"];
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
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
    
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
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

@end


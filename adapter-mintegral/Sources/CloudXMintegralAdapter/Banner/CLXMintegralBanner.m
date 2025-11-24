#import "CLXMintegralBanner.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralBanner ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation CLXMintegralBanner

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                              size:(CGSize)size
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterBannerDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _unitID = [unitID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMintegralInitializer sdkVersion];
        _network = @"mintegral";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralBanner"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID:%@, UnitID:%@, Size:%.0fx%.0f", 
                           placementID, unitID, size.width, size.height]];
        
        _bannerView = [[MTGBidBannerAdView alloc] initBannerAdViewWithPlacementId:placementID
                                                                            unitId:unitID
                                                                      rootViewController:nil
                                                                          adSize:size
                                                                        delegate:self];
    }
    return self;
}

- (void)load {
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading banner - PlacementID:%@, UnitID:%@", _placementID, _unitID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload && self.bidPayload.length > 0) {
            [self.bannerView loadBannerAdWithBidToken:self.bidPayload];
        } else {
            [self.bannerView loadBannerAd];
        }
    });
}

#pragma mark - MTGBidBannerAdViewDelegate

- (void)adViewLoadSuccess:(MTGBidBannerAdView *)adView {
    [self.logger info:@"Loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    }
}

- (void)adViewLoadFailedWithError:(NSError *)error adView:(MTGBidBannerAdView *)adView {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Banner Load"
                                                            placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:mappedError];
    }
}

- (void)adViewWillLogImpression:(MTGBidBannerAdView *)adView {
    [self.logger info:@"Did present"];
    
    // Forward the display callback to the SDK
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
    
    // Forward impression tracking
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

- (void)adViewDidClicked:(MTGBidBannerAdView *)adView {
    [self.logger info:@"Did click"];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)adViewClosed:(MTGBidBannerAdView *)adView {
    [self.logger info:@"Did close"];
    
    if ([self.delegate respondsToSelector:@selector(closeBanner:)]) {
        [self.delegate closeBanner:self];
    }
}

@end


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
        _autoRefreshTime = 0;  // Disabled by default
        _showCloseButton = NO; // Hidden by default
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralBanner"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID:%@, UnitID:%@, Size:%.0fx%.0f", 
                           placementID, unitID, size.width, size.height]];
        
        // Convert CGSize to MTGBannerSizeType
        MTGBannerSizeType sizeType = [self bannerSizeTypeFromSize:size];
        
        // Use MTGBannerAdView (supports both bidding and waterfall)
        _bannerView = [[MTGBannerAdView alloc] initBannerAdViewWithBannerSizeType:sizeType
                                                                      placementId:placementID
                                                                           unitId:unitID
                                                               rootViewController:nil];
        _bannerView.delegate = self;
        
        // Configure banner settings (matching AppLovin implementation)
        _bannerView.autoRefreshTime = _autoRefreshTime;
        _bannerView.showCloseButton = _showCloseButton ? MTGBoolYes : MTGBoolNo;
    }
    return self;
}

- (MTGBannerSizeType)bannerSizeTypeFromSize:(CGSize)size {
    // Standard banner sizes
    if (size.width == 320 && size.height == 50) {
        return MTGStandardBannerType320x50;
    } else if (size.width == 320 && size.height == 90) {
        return MTGLargeBannerType320x90;
    } else if (size.width == 300 && size.height == 250) {
        return MTGMediumRectangularBanner300x250;
    } else if (size.width == 728 && size.height == 90) {
        return MTGLeaderboardBannerType728x90;
    } else {
        // Default to smart banner for unknown sizes
        return MTGSmartBannerType;
    }
}

- (void)load {
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading banner - PlacementID:%@, UnitID:%@", _placementID, _unitID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update settings before loading
        self.bannerView.autoRefreshTime = self.autoRefreshTime;
        self.bannerView.showCloseButton = self.showCloseButton ? MTGBoolYes : MTGBoolNo;
        
        if (self.bidPayload && self.bidPayload.length > 0) {
            [self.bannerView loadBannerAdWithBidToken:self.bidPayload];
        } else {
            [self.bannerView loadBannerAd];
        }
    });
}

- (void)destroy {
    [self.logger debug:@"Destroying banner"];
    [self.bannerView destroyBannerAdView];
    self.bannerView.delegate = nil;
    self.bannerView = nil;
}

#pragma mark - MTGBannerAdViewDelegate

- (void)adViewLoadSuccess:(MTGBannerAdView *)adView {
    [self.logger info:@"Loaded successfully"];
    _isLoading = NO;
    
    // Retrieve creative ID
    _creativeID = adView.creativeId;
    if (_creativeID) {
        [self.logger debug:[NSString stringWithFormat:@"Creative ID: %@", _creativeID]];
    }
    
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    }
}

- (void)adViewLoadFailedWithError:(NSError *)error adView:(MTGBannerAdView *)adView {
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

- (void)adViewWillLogImpression:(MTGBannerAdView *)adView {
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

- (void)adViewDidClicked:(MTGBannerAdView *)adView {
    [self.logger info:@"Did click"];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

- (void)adViewWillLeaveApplication:(MTGBannerAdView *)adView {
    [self.logger debug:@"Will leave application"];
}

- (void)adViewWillOpenFullScreen:(MTGBannerAdView *)adView {
    [self.logger debug:@"Expanded"];
}

- (void)adViewCloseFullScreen:(MTGBannerAdView *)adView {
    [self.logger debug:@"Collapsed"];
}

- (void)adViewClosed:(MTGBannerAdView *)adView {
    [self.logger info:@"Did close"];
    
    if ([self.delegate respondsToSelector:@selector(closeBanner:)]) {
        [self.delegate closeBanner:self];
    }
}

@end


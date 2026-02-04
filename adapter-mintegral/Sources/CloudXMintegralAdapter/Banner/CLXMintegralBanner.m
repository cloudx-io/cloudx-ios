#import "CLXMintegralBanner.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralBanner ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign) CGSize bannerSize;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, strong, nullable) MTGBannerAdView *mintegralBannerView;
@end

@implementation CLXMintegralBanner

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                              size:(CGSize)size
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterBannerDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _adUnitName = [adUnitName copy];
        _unitID = [unitID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMintegralInitializer sdkVersion];
        _network = @"mintegral";
        _autoRefreshTime = 0;
        _showCloseButton = NO;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralBanner"];
        _isDestroyed = NO;
        _timeout = NO;
        _bannerSize = size;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@, PlacementID:%@, UnitID:%@, Size:%.0fx%.0f", 
                           adUnitName ?: @"(unknown)", placementID, unitID, size.width, size.height]];
    }
    return self;
}

- (void)dealloc {
    [self destroy];
}

#pragma mark - Banner Size Conversion

- (MTGBannerSizeType)bannerSizeTypeFromSize:(CGSize)size {
    if (size.width == 320 && size.height == 50) {
        return MTGStandardBannerType320x50;
    } else if (size.width == 320 && size.height == 90) {
        return MTGLargeBannerType320x90;
    } else if (size.width == 300 && size.height == 250) {
        return MTGMediumRectangularBanner300x250;
    } else {
        return MTGSmartBannerType;
    }
}

#pragma mark - Public Properties

- (UIView *)bannerView {
    return self.mintegralBannerView;
}

#pragma mark - CLXAdapterBanner Protocol

- (void)load {
    if (self.isDestroyed) {
        [self.logger error:@"Cannot load - adapter is destroyed"];
        return;
    }
    
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    // Validate unitID at load time
    if (!_unitID || _unitID.length == 0) {
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Mintegral unit ID is empty%@. "
                                  "Make sure to configure the Mintegral unit ID in your CloudX dashboard under Ad Unit Settings > Mintegral.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading banner - Placement: %@, PlacementID:%@, UnitID:%@", _adUnitName ?: @"(unknown)", _placementID, _unitID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isDestroyed) {
            return;
        }
        
        if (!self.mintegralBannerView) {
            MTGBannerSizeType sizeType = [self bannerSizeTypeFromSize:self.bannerSize];
            self.mintegralBannerView = [[MTGBannerAdView alloc] initBannerAdViewWithBannerSizeType:sizeType
                                                                                      placementId:self.placementID
                                                                                           unitId:self.unitID
                                                                               rootViewController:nil];
            self.mintegralBannerView.delegate = self;
        }
        
        self.mintegralBannerView.autoRefreshTime = self.autoRefreshTime;
        self.mintegralBannerView.showCloseButton = self.showCloseButton ? MTGBoolYes : MTGBoolNo;
        
        if (self.bidPayload && self.bidPayload.length > 0) {
            [self.mintegralBannerView loadBannerAdWithBidToken:self.bidPayload];
        } else {
            [self.mintegralBannerView loadBannerAd];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (self.isDestroyed) {
        [self.logger error:@"Cannot show - adapter is destroyed"];
        return;
    }
    
    [self.logger info:@"Showing banner"];
    
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
}

- (void)destroy {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger debug:@"Destroying banner adapter"];
    self.isDestroyed = YES;
    
    if (self.mintegralBannerView) {
        [self.mintegralBannerView removeFromSuperview];
        [self.mintegralBannerView destroyBannerAdView];
        self.mintegralBannerView.delegate = nil;
        self.mintegralBannerView = nil;
    }
    
    self.delegate = nil;
    self.isLoading = NO;
}

#pragma mark - MTGBannerAdViewDelegate

- (void)adViewLoadSuccess:(MTGBannerAdView *)adView {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Banner loaded successfully"];
    _isLoading = NO;
    _creativeID = adView.creativeId;
    
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didLoadBanner:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didLoadBanner:self];
        });
    }
}

- (void)adViewLoadFailedWithError:(NSError *)error adView:(MTGBannerAdView *)adView {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Banner Load"
                                                            placementID:_placementID];
    
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate failToLoadBanner:self error:mappedError];
        });
    }
}

- (void)adViewWillLogImpression:(MTGBannerAdView *)adView {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Banner displayed"];
    
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (!delegate) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([delegate respondsToSelector:@selector(didShowBanner:)]) {
            [delegate didShowBanner:self];
        }
        
        if ([delegate respondsToSelector:@selector(impressionBanner:)]) {
            [delegate impressionBanner:self];
        }
    });
}

- (void)adViewDidClicked:(MTGBannerAdView *)adView {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Banner clicked"];
    
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(clickBanner:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate clickBanner:self];
        });
    }
}

- (void)adViewWillLeaveApplication:(MTGBannerAdView *)adView {
    [self.logger debug:@"Will leave application"];
}

- (void)adViewWillOpenFullScreen:(MTGBannerAdView *)adView {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Banner expanded"];
    
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didExpandBanner:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didExpandBanner:self];
        });
    }
}

- (void)adViewCloseFullScreen:(MTGBannerAdView *)adView {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Banner collapsed"];
    
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didCollapseBanner:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didCollapseBanner:self];
        });
    }
}

- (void)adViewClosed:(MTGBannerAdView *)adView {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Banner closed"];
    
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(closedByUserActionBanner:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate closedByUserActionBanner:self];
        });
    }
}

@end

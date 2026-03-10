#import "CLXMintegralBanner.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXUIApplicationProxy.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralBanner ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) CGSize bannerSize;
@property (nonatomic, copy) NSString *network;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, copy) NSString *unitID;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy, nullable) NSString *creativeID;
@property (nonatomic, assign) NSInteger autoRefreshTime;
@property (nonatomic, assign) BOOL showCloseButton;
@property (nonatomic, strong, nullable) MTGBannerAdView *mintegralBannerView;
@end

@implementation CLXMintegralBanner

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                              size:(CGSize)size
                             bidID:(NSString *)bidID
                   hasClosedButton:(BOOL)hasClosedButton
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
        _showCloseButton = hasClosedButton;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralBanner"];
        _timeout = NO;
        _bannerSize = size;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@, PlacementID:%@, UnitID:%@, Size:%.0fx%.0f", 
                           adUnitName ?: @"(unknown)", placementID, unitID, size.width, size.height]];
    }
    return self;
}

#pragma mark - Banner Size Conversion

- (MTGBannerSizeType)bannerSizeTypeFromSize:(CGSize)size {
    if (size.width == 320 && size.height == 50) {
        return MTGStandardBannerType320x50;
    } else if (size.width == 320 && size.height == 90) {
        return MTGLargeBannerType320x90;
    } else if (size.width == 300 && size.height == 250) {
        return MTGMediumRectangularBanner300x250;
    } else if (size.width == 728 && size.height == 90) {
        return MTGSmartBannerType; // Leaderboard - use smart banner
    } else {
        [self.logger debug:[NSString stringWithFormat:@"Unknown banner size %.0fx%.0f, using smart banner", size.width, size.height]];
        return MTGSmartBannerType;
    }
}

#pragma mark - Public Properties

- (UIView *)bannerView {
    return self.mintegralBannerView;
}

#pragma mark - CLXAdapterBanner Protocol

- (void)load {
    if (!_unitID || _unitID.length == 0) {
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Mintegral unit ID is empty%@. "
                                  "Make sure to configure the Mintegral unit ID in your CloudX dashboard under Ad Unit Settings > Mintegral.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];
        [self.delegate failToLoadBanner:self error:error];
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Loading banner - Placement: %@, PlacementID:%@, UnitID:%@", _adUnitName ?: @"(unknown)", _placementID, _unitID]];

    if (!self.mintegralBannerView) {
        MTGBannerSizeType sizeType = [self bannerSizeTypeFromSize:self.bannerSize];
        self.mintegralBannerView = [[MTGBannerAdView alloc] initBannerAdViewWithBannerSizeType:sizeType
                                                                                  placementId:self.placementID
                                                                                       unitId:self.unitID
                                                                           rootViewController:[CLXUIApplicationProxy topViewController]];
        self.mintegralBannerView.delegate = self;
    }
    
    self.mintegralBannerView.autoRefreshTime = self.autoRefreshTime;
    self.mintegralBannerView.showCloseButton = self.showCloseButton ? MTGBoolYes : MTGBoolNo;
    
    if (self.bidPayload && self.bidPayload.length > 0) {
        [self.mintegralBannerView loadBannerAdWithBidToken:self.bidPayload];
    } else {
        [self.mintegralBannerView loadBannerAd];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (self.mintegralBannerView && viewController) {
        self.mintegralBannerView.viewController = viewController;
    }

    [self.logger debug:@"showFromViewController called - impression will be tracked in adViewWillLogImpression"];
    // Note: Do not fire didShowBanner here. The impression callback fires in adViewWillLogImpression:
    // when the banner is actually displayed to the user.
}

- (void)destroy {
    [self.logger debug:@"Destroying banner adapter"];
    
    if (self.mintegralBannerView) {
        self.mintegralBannerView.delegate = nil;
        [self.mintegralBannerView destroyBannerAdView];
        self.mintegralBannerView = nil;
    }
    
    self.delegate = nil;
}

#pragma mark - MTGBannerAdViewDelegate

- (void)adViewLoadSuccess:(MTGBannerAdView *)adView {
    [self.logger info:@"Banner loaded successfully"];
    _creativeID = adView.creativeId;
    [self.delegate didLoadBanner:self];
}

- (void)adViewLoadFailedWithError:(NSError *)error adView:(MTGBannerAdView *)adView {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    CLXError *mappedError = [CLXMintegralErrorHandler toCloudXError:error];
    [self.delegate failToLoadBanner:self error:mappedError];
}

- (void)adViewWillLogImpression:(MTGBannerAdView *)adView {
    [self.logger info:@"Banner displayed"];
    [self.delegate didShowBanner:self];
    [self.delegate impressionBanner:self];
}

- (void)adViewDidClicked:(MTGBannerAdView *)adView {
    [self.logger info:@"Banner clicked"];
    [self.delegate clickBanner:self];
}

- (void)adViewWillLeaveApplication:(MTGBannerAdView *)adView {
    [self.logger debug:@"Will leave application"];
}

- (void)adViewWillOpenFullScreen:(MTGBannerAdView *)adView {
    [self.logger info:@"Banner expanded"];
    [self.delegate didExpandBanner:self];
}

- (void)adViewCloseFullScreen:(MTGBannerAdView *)adView {
    [self.logger info:@"Banner collapsed"];
    [self.delegate didCollapseBanner:self];
}

- (void)adViewClosed:(MTGBannerAdView *)adView {
    [self.logger info:@"Banner closed"];
    [self.delegate closedByUserActionBanner:self];
}

@end

//
//  CLXVungleBanner.m
//  CloudXVungleAdapter
//

#import "CLXVungleBanner.h"
#import "CLXVungleErrorHandler.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVungleBanner ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, copy, readwrite) NSString *placementID;
@property (nonatomic, copy, readwrite, nullable) NSString *adUnitName;
@property (nonatomic, assign, readwrite) CLXBannerType bannerType;
@property (nonatomic, strong, nullable) VungleBannerView *vungleBannerView;
@property (nonatomic, assign) BOOL isLoaded;
@end

@implementation CLXVungleBanner

@synthesize timeout = _timeout;

#pragma mark - Initialization

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type
                          delegate:(nullable id<CLXAdapterBannerDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _adUnitName = [adUnitName copy];
        _bannerType = type;
        _delegate = delegate;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXVungleBanner"];
        _isLoaded = NO;

        [_logger debug:[NSString stringWithFormat:@"Initialized Vungle banner - Placement: %@ (%@), BidID: %@, Type: %ld, HasBidPayload: %@",
                          adUnitName ?: @"(unknown)", placementID ?: @"(nil)", bidID, (long)type, bidPayload ? @"YES" : @"NO"]];
    }
    return self;
}

#pragma mark - Public Properties

- (NSString *)sdkVersion {
    return [VungleAds sdkVersion] ?: @"unknown";
}

- (UIView *)bannerView {
    return self.vungleBannerView;
}

#pragma mark - CLXAdapterBanner Protocol

- (void)load {
    if (!self.placementID || self.placementID.length == 0) {
        NSString *adUnitContext = self.adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", self.adUnitName] : @"";
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:[NSString stringWithFormat:@"Vungle placement ID is empty%@. "
                                      "Configure the Vungle placement ID in CloudX dashboard under Ad Unit Settings > Vungle.",
                                      adUnitContext]];
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

    [self.logger info:[NSString stringWithFormat:@"Loading banner for placement: %@", self.placementID]];

    VungleAdSize *vungleAdSize = [self vungleAdSizeFromBannerType:self.bannerType];
    if (!vungleAdSize) {
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidConfiguration
                                     description:@"Unsupported banner type"];
        [self handleLoadFailure:error];
        return;
    }

    self.vungleBannerView = [[VungleBannerView alloc] initWithPlacementId:self.placementID
                                                            vungleAdSize:vungleAdSize];
    self.vungleBannerView.delegate = self;
    [self.vungleBannerView load:self.bidPayload];
}

- (void)showFromViewController:(UIViewController *)viewController {
    [self.logger info:@"Showing banner ad"];
    // Note: didShowBanner is called in bannerAdDidTrackImpression
}

- (void)destroy {
    [self.logger debug:@"Destroying banner adapter"];

    self.vungleBannerView.delegate = nil;
    self.vungleBannerView = nil;
    self.delegate = nil;
    self.isLoaded = NO;
}

#pragma mark - VungleBannerViewDelegate

- (void)bannerAdDidLoad:(VungleBannerView *)bannerView {
    [self.logger info:@"Banner ad loaded"];
    self.isLoaded = YES;

    [self.delegate didLoadBanner:self];
}

- (void)bannerAdDidFail:(VungleBannerView *)bannerView withError:(NSError *)error {
    if (self.isLoaded) {
        [self handleShowFailure:error];
    } else {
        [self handleLoadFailure:error];
    }
}

- (void)bannerAdWillPresent:(VungleBannerView *)bannerView {
    [self.logger debug:@"Banner ad will present"];
}

- (void)bannerAdDidPresent:(VungleBannerView *)bannerView {
    [self.logger debug:@"Banner ad did present"];
    // Note: didShowBanner fires in didTrackImpression
}

- (void)bannerAdDidTrackImpression:(VungleBannerView *)bannerView {
    [self.logger info:@"Banner ad impression tracked"];

    // Fire show then impression together
    [self.delegate didShowBanner:self];
    [self.delegate impressionBanner:self];
}

- (void)bannerAdDidClick:(VungleBannerView *)bannerView {
    [self.logger info:@"Banner ad clicked"];

    [self.delegate clickBanner:self];
}

- (void)bannerAdWillLeaveApplication:(VungleBannerView *)bannerView {
    [self.logger debug:@"Banner ad will leave application"];
}

- (void)bannerAdWillClose:(VungleBannerView *)bannerView {
    [self.logger debug:@"Banner ad will close"];
}

- (void)bannerAdDidClose:(VungleBannerView *)bannerView {
    [self.logger info:@"Banner ad closed"];

    [self.delegate closedByUserActionBanner:self];
}

#pragma mark - Private Methods

- (nullable VungleAdSize *)vungleAdSizeFromBannerType:(CLXBannerType)bannerType {
    switch (bannerType) {
        case CLXBannerTypeW320H50:
            return [VungleAdSize VungleAdSizeBannerRegular];

        case CLXBannerTypeMREC:
            return [VungleAdSize VungleAdSizeMREC]; // 300x250

        default:
            [self.logger error:[NSString stringWithFormat:@"Unsupported banner type: %ld", (long)bannerType]];
            return nil;
    }
}

- (void)handleLoadFailure:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Banner load failed for placement %@: %@", self.placementID, error.localizedDescription]];
    CLXError *clxError = [CLXVungleErrorHandler toCloudXError:error isShowError:NO];
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (delegate) {
        [delegate failToLoadBanner:self error:clxError];
    }
}

- (void)handleShowFailure:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Banner show failed for placement %@: %@", self.placementID, error.localizedDescription]];
    CLXError *clxError = [CLXVungleErrorHandler toCloudXError:error isShowError:YES];
    id<CLXAdapterBannerDelegate> delegate = self.delegate;
    if (delegate) {
        [delegate failToLoadBanner:self error:clxError];
    }
}

@end

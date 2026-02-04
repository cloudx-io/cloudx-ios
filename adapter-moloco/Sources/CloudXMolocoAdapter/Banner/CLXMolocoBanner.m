//
//  CLXMolocoBanner.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBanner.h>)
#import <CloudXMolocoAdapter/CLXMolocoBanner.h>
#else
#import "CLXMolocoBanner.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

#if __has_include(<CloudXMolocoAdapter/CLXMolocoInitializer.h>)
#import <CloudXMolocoAdapter/CLXMolocoInitializer.h>
#else
#import "../Initializers/CLXMolocoInitializer.h"
#endif

#if __has_include(<CloudXMolocoAdapter/CLXMolocoErrorHandler.h>)
#import <CloudXMolocoAdapter/CLXMolocoErrorHandler.h>
#else
#import "../Utils/CLXMolocoErrorHandler.h"
#endif

@interface CLXMolocoBanner () {
    NSString *_bidID;
}

@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) CLXBannerAdSize adSize;
@property (nonatomic, copy, nullable) NSString *adUnitName;

@end

@implementation CLXMolocoBanner

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterBannerDelegate>)delegate
                            adSize:(CLXBannerAdSize)adSize {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];  // Now nullable - validation in load()
        _adUnitName = [adUnitName copy];  // For error messages
        _bidID = [bidID copy];
        _delegate = delegate;
        _adSize = adSize;
        _sdkVersion = [CLXMolocoInitializer sdkVersion];
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMolocoBanner"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@ (%@), BidID: %@, Size: %dx%d", 
                           adUnitName ?: @"(unknown)", placementID ?: @"(nil)", bidID, (int)adSize.width, (int)adSize.height]];
        
        // Only create banner view if placementID is valid
        // Otherwise defer to load() for validation
        if (placementID && placementID.length > 0) {
            CGSize molocoSize = CGSizeMake(adSize.width, adSize.height);
            _bannerView = [[MolocoBannerView alloc] initWithPlacementID:placementID size:molocoSize];
            _bannerView.delegate = self;
        }
    }
    return self;
}

- (NSString *)bidID {
    return _bidID;
}

- (NSString *)network {
    return @"moloco";
}

- (void)load {
    // Validate placement ID at load time (deferred validation pattern)
    if (!_placementID || _placementID.length == 0) {
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Moloco placement ID is empty%@. "
                                  "Make sure to configure the Moloco placement ID in your CloudX dashboard under Ad Unit Settings > Moloco.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];
        
        if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
            [self.delegate failToLoadBanner:self error:error];
        }
        return;
    }
    
    // Create banner view now if not already created (deferred from init)
    if (!_bannerView) {
        CGSize molocoSize = CGSizeMake(_adSize.width, _adSize.height);
        _bannerView = [[MolocoBannerView alloc] initWithPlacementID:_placementID size:molocoSize];
        _bannerView.delegate = self;
        [self.logger debug:@"Created banner view with validated placement ID"];
    }
    
    if (_isLoading) {
        [self.logger debug:@"Load already in progress"];
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading banner - Placement: %@", _placementID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload) {
            [self.bannerView loadWithBidPayload:self.bidPayload];
        } else {
            [self.bannerView load];
        }
    });
}

- (void)loadAd {
    [self load];
}

- (UIView *)view {
    return _bannerView;
}

- (void)destroy {
    [self.logger debug:@"Destroying banner"];
    
    if (self.bannerView) {
        self.bannerView.delegate = nil;
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
    }
    
    self.delegate = nil;
    _isLoading = NO;
    
    [self.logger debug:@"Destruction complete"];
}

#pragma mark - MolocoBannerDelegate

- (void)molocoBannerDidLoad:(MolocoBannerView *)bannerView {
    [self.logger info:@"Banner loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadBanner:)]) {
        [self.delegate didLoadBanner:self];
    }
}

- (void)molocoBanner:(MolocoBannerView *)bannerView didFailToLoadWithError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMolocoErrorHandler handleMolocoError:error
                                                         withLogger:self.logger
                                                            context:@"Banner Load"
                                                        placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(failToLoadBanner:error:)]) {
        [self.delegate failToLoadBanner:self error:mappedError];
    }
}

- (void)molocoBannerWillAppear:(MolocoBannerView *)bannerView {
    [self.logger debug:@"Banner will appear"];
    
    // Forward the display callback to the SDK
    if ([self.delegate respondsToSelector:@selector(didShowBanner:)]) {
        [self.delegate didShowBanner:self];
    }
    
    // Forward impression tracking
    if ([self.delegate respondsToSelector:@selector(impressionBanner:)]) {
        [self.delegate impressionBanner:self];
    }
}

- (void)molocoBannerDidClick:(MolocoBannerView *)bannerView {
    [self.logger info:@"Banner clicked"];
    
    if ([self.delegate respondsToSelector:@selector(clickBanner:)]) {
        [self.delegate clickBanner:self];
    }
}

@end


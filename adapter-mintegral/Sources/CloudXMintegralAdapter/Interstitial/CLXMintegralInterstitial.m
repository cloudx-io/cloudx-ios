#import "CLXMintegralInterstitial.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralInterstitial ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation CLXMintegralInterstitial

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _unitID = [unitID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMintegralInitializer sdkVersion];
        _network = @"mintegral";
        _playVideoMute = NO;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralInterstitial"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID:%@, UnitID:%@, BidID:%@", 
                           placementID, unitID, bidID]];
        
        // Use the NEW Interstitial Bid Ad Manager (matches AppLovin implementation)
        _interstitialManager = [[MTGNewInterstitialBidAdManager alloc] initWithPlacementId:placementID 
                                                                                    unitId:unitID 
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
    [self.logger debug:[NSString stringWithFormat:@"Loading ad - PlacementID:%@, UnitID:%@", _placementID, _unitID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Apply mute setting before loading
        self.interstitialManager.playVideoMute = self.playVideoMute;
        
        if (self.bidPayload && self.bidPayload.length > 0) {
            [self.interstitialManager loadAdWithBidToken:self.bidPayload];
        } else {
            [self.interstitialManager loadAd];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = self.interstitialManager && [self.interstitialManager isAdReady];
    
    if (ready) {
        [self.logger info:@"Showing interstitial"];
        
        // Retrieve creative ID before showing
        _creativeID = [self.interstitialManager getCreativeIdWithUnitId:self.interstitialManager.currentUnitId];
        if (_creativeID) {
            [self.logger debug:[NSString stringWithFormat:@"Creative ID: %@", _creativeID]];
        }
        
        if ([self.delegate respondsToSelector:@selector(didShowWithInterstitial:)]) {
            [self.delegate didShowWithInterstitial:self];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.interstitialManager showFromViewController:viewController];
        });
    } else {
        [self.logger error:@"Cannot show - ad not ready"];
        
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdNotReady
                                     description:@"Interstitial not ready"];
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
            [self.delegate didFailToShowWithInterstitial:self error:error];
        }
    }
}

#pragma mark - MTGNewInterstitialBidAdDelegate

- (void)newInterstitialBidAdResourceLoadSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    // Ad has loaded and video has been downloaded
    [self.logger info:@"Loaded successfully (video downloaded)"];
    _isLoading = NO;
    
    // Retrieve creative ID
    _creativeID = [adManager getCreativeIdWithUnitId:adManager.currentUnitId];
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)newInterstitialBidAdLoadSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    // Ad has loaded but video still needs to be downloaded
    [self.logger debug:@"Ad loaded, video downloading..."];
}

- (void)newInterstitialBidAdLoadFail:(NSError *)error adManager:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Interstitial Load"
                                                            placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithInterstitial:error:)]) {
        [self.delegate didFailToLoadWithInterstitial:self error:mappedError];
    }
}

- (void)newInterstitialBidAdShowSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger info:@"Did present"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)newInterstitialBidAdShowFail:(NSError *)error adManager:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Interstitial Show"
                                                            placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:self error:mappedError];
    }
}

- (void)newInterstitialBidAdClicked:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger info:@"Did click"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

- (void)newInterstitialBidAdDismissedWithConverted:(BOOL)converted adManager:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger info:@"Did dismiss"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

- (void)newInterstitialBidAdDidClosed:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"Video completed"];
}

- (void)newInterstitialBidAdEndCardShowSuccess:(MTGNewInterstitialBidAdManager *)adManager {
    [self.logger debug:@"End card shown"];
}

@end


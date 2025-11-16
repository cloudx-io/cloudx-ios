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
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralInterstitial"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID:%@, UnitID:%@, BidID:%@", 
                           placementID, unitID, bidID]];
        
        _interstitialManager = [[MTGBidInterstitialVideoAdManager alloc] initWithPlacementId:placementID 
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
        if (self.bidPayload && self.bidPayload.length > 0) {
            [self.interstitialManager loadAdWithBidToken:self.bidPayload];
        } else {
            [self.interstitialManager loadAd];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = self.interstitialManager && [self.interstitialManager isVideoReadyToPlay:_placementID unitId:_unitID];
    
    if (ready) {
        [self.logger info:@"Showing interstitial"];
        
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

#pragma mark - MTGBidInterstitialVideoDelegate

- (void)onInterstitialVideoLoadSuccess:(MTGBidInterstitialVideoAdManager *)adManager {
    [self.logger info:@"Loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithInterstitial:)]) {
        [self.delegate didLoadWithInterstitial:self];
    }
}

- (void)onInterstitialVideoLoadFail:(nonnull NSError *)error adManager:(MTGBidInterstitialVideoAdManager *)adManager {
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

- (void)onInterstitialVideoShowSuccess:(MTGBidInterstitialVideoAdManager *)adManager {
    [self.logger info:@"Did present"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithInterstitial:)]) {
        [self.delegate impressionWithInterstitial:self];
    }
}

- (void)onInterstitialVideoShowFail:(nonnull NSError *)error adManager:(MTGBidInterstitialVideoAdManager *)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Interstitial Show"
                                                            placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithInterstitial:error:)]) {
        [self.delegate didFailToShowWithInterstitial:self error:mappedError];
    }
}

- (void)onInterstitialVideoAdClick:(MTGBidInterstitialVideoAdManager *)adManager {
    [self.logger info:@"Did click"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithInterstitial:)]) {
        [self.delegate clickWithInterstitial:self];
    }
}

- (void)onInterstitialVideoAdDismissedWithConverted:(BOOL)converted adManager:(MTGBidInterstitialVideoAdManager *)adManager {
    [self.logger info:@"Did dismiss"];
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithInterstitial:)]) {
        [self.delegate didCloseWithInterstitial:self];
    }
}

@end


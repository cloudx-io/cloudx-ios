#import "CLXMintegralRewarded.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralRewarded ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation CLXMintegralRewarded

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
    self = [super init];
    if (self) {
        _bidPayload = [bidPayload copy];
        _placementID = [placementID copy];
        _unitID = [unitID copy];
        _bidID = [bidID copy];
        _delegate = delegate;
        _sdkVersion = [CLXMintegralInitializer sdkVersion];
        _network = @"mintegral";
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralRewarded"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID:%@, UnitID:%@, BidID:%@", 
                           placementID, unitID, bidID]];
        
        _rewardedManager = [[MTGBidRewardAdManager alloc] initWithPlacementId:placementID 
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
    [self.logger debug:[NSString stringWithFormat:@"Loading rewarded - PlacementID:%@, UnitID:%@", _placementID, _unitID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bidPayload && self.bidPayload.length > 0) {
            [self.rewardedManager loadAdWithBidToken:self.bidPayload];
        } else {
            [self.rewardedManager loadAd];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = self.rewardedManager && [self.rewardedManager isVideoReadyToPlay:_placementID unitId:_unitID];
    
    if (ready) {
        [self.logger info:@"Showing rewarded"];
        
        if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
            [self.delegate didShowWithRewarded:self];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rewardedManager showAdWithViewController:viewController];
        });
    } else {
        [self.logger error:@"Cannot show - ad not ready"];
        
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdNotReady
                                     description:@"Rewarded ad not ready"];
        if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
            [self.delegate didFailToShowWithRewarded:self error:error];
        }
    }
}

#pragma mark - MTGBidRewardAdLoadDelegate

- (void)onAdLoadSuccess:(nullable id)adManager {
    [self.logger info:@"Loaded successfully"];
    _isLoading = NO;
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:self];
    }
}

- (void)onVideoAdLoadFailed:(nullable NSError *)error adManager:(nullable id)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Rewarded Load"
                                                            placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
        [self.delegate didFailToLoadWithRewarded:self error:mappedError];
    }
}

#pragma mark - MTGBidRewardAdShowDelegate

- (void)onAdShowSuccess:(nullable id)adManager {
    [self.logger info:@"Did present"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

- (void)onVideoAdShowFailed:(nullable NSError *)error adManager:(nullable id)adManager {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Rewarded Show"
                                                            placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        [self.delegate didFailToShowWithRewarded:self error:mappedError];
    }
}

- (void)onAdClicked:(nullable id)adManager {
    [self.logger info:@"Did click"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
}

- (void)onAdDismissed:(nullable id)adManager withConverted:(BOOL)converted withRewardInfo:(nullable MTGRewardAdInfo *)rewardInfo {
    [self.logger info:[NSString stringWithFormat:@"Did dismiss - Converted:%d", converted]];
    
    if (converted && [self.delegate respondsToSelector:@selector(rewardedWithRewarded:)]) {
        [self.delegate rewardedWithRewarded:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
    }
}

@end


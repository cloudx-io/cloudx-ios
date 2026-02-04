#import "CLXMintegralRewarded.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralRewarded ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isDestroyed;
@property (nonatomic, assign, readwrite) BOOL isReady;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@end

@implementation CLXMintegralRewarded

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate {
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
        _playVideoMute = NO;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralRewarded"];
        _isDestroyed = NO;
        _isReady = NO;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@, PlacementID:%@, UnitID:%@", adUnitName ?: @"(unknown)", placementID, unitID]];
    }
    return self;
}

- (void)dealloc {
    [self destroy];
}

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
        
        if ([self.delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
            [self.delegate didFailToLoadWithRewarded:self error:error];
        }
        return;
    }
    
    _isLoading = YES;
    [self.logger debug:[NSString stringWithFormat:@"Loading rewarded - Placement: %@, PlacementID:%@, UnitID:%@", _adUnitName ?: @"(unknown)", _placementID, _unitID]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isDestroyed) {
            return;
        }
        
        // Apply mute setting before loading
        [MTGBidRewardAdManager sharedInstance].playVideoMute = self.playVideoMute;
        
        if (self.bidPayload && self.bidPayload.length > 0) {
            // Bidding flow - use MTGBidRewardAdManager with bid token
            [[MTGBidRewardAdManager sharedInstance] loadVideoWithBidToken:self.bidPayload
                                                              placementId:self.placementID
                                                                   unitId:self.unitID
                                                                 delegate:self];
        } else {
            // Non-bidding (waterfall) flow - use MTGRewardAdManager
            [[MTGRewardAdManager sharedInstance] loadVideoWithPlacementId:self.placementID
                                                                   unitId:self.unitID
                                                                 delegate:self];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    if (self.isDestroyed) {
        [self.logger error:@"Cannot show - adapter is destroyed"];
        return;
    }
    
    BOOL ready = self.isReady && [[MTGBidRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId:_placementID unitId:_unitID];
    
    if (ready) {
        [self.logger info:@"Showing rewarded"];
        
        // Retrieve creative ID before showing
        _creativeID = [[MTGBidRewardAdManager sharedInstance] getCreativeIdWithUnitId:_unitID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MTGBidRewardAdManager sharedInstance] showVideoWithPlacementId:self.placementID
                                                                      unitId:self.unitID
                                                                withRewardId:nil
                                                                      userId:nil
                                                                    delegate:self
                                                              viewController:viewController];
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

#pragma mark - MTGRewardAdLoadDelegate

- (void)onVideoAdLoadSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Rewarded loaded successfully"];
    _isLoading = NO;
    _isReady = YES;
    
    // Retrieve creative ID
    _creativeID = [[MTGBidRewardAdManager sharedInstance] getCreativeIdWithUnitId:unitId];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterRewardedDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didLoadWithRewarded:self];
        });
    }
}

- (void)onAdLoadSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"Ad loaded, video downloading..."];
}

- (void)onVideoAdLoadFailed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId error:(NSError *)error {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isLoading = NO;
    _isReady = NO;
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Rewarded Load"
                                                            placementID:_placementID];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterRewardedDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didFailToLoadWithRewarded:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didFailToLoadWithRewarded:self error:mappedError];
        });
    }
}

#pragma mark - MTGRewardAdShowDelegate

- (void)onVideoAdShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Rewarded displayed"];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterRewardedDelegate> delegate = self.delegate;
    if (!delegate) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
            [delegate didShowWithRewarded:self];
        }
        
        if ([delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
            [delegate impressionWithRewarded:self];
        }
    });
}

- (void)onVideoAdShowFailed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId withError:(NSError *)error {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Rewarded Show"
                                                            placementID:_placementID];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterRewardedDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate didFailToShowWithRewarded:self error:mappedError];
        });
    }
}

- (void)onVideoAdClicked:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:@"Rewarded clicked"];
    
    // Capture strong reference to delegate before dispatching to main thread
    id<CLXAdapterRewardedDelegate> delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate clickWithRewarded:self];
        });
    }
}

- (void)onVideoAdDismissed:(nullable NSString *)placementId 
                    unitId:(nullable NSString *)unitId 
             withConverted:(BOOL)converted 
            withRewardInfo:(nullable MTGRewardAdInfo *)rewardInfo {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger info:[NSString stringWithFormat:@"Rewarded hidden - converted:%d", converted]];
    _isReady = NO;
    
    // Capture strong reference to delegate and reward info before dispatching to main thread
    id<CLXAdapterRewardedDelegate> delegate = self.delegate;
    NSInteger rewardAmount = rewardInfo ? rewardInfo.rewardAmount : 0;
    NSString *rewardName = rewardInfo ? [rewardInfo.rewardName copy] : nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (converted && delegate && [delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
            if (rewardInfo && [delegate respondsToSelector:@selector(userRewardWithRewarded:amount:label:)]) {
                [delegate userRewardWithRewarded:self amount:rewardAmount label:rewardName];
            } else {
                [delegate userRewardWithRewarded:self];
            }
        }
        
        if (delegate && [delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
            [delegate didCloseWithRewarded:self];
        }
    });
}

- (void)onVideoAdDidClosed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"Video closed"];
}

- (void)onVideoPlayCompleted:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"Video play completed"];
}

- (void)onEndcardShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"End card shown"];
}

#pragma mark - Lifecycle

- (void)destroy {
    if (self.isDestroyed) {
        return;
    }
    
    [self.logger debug:@"Destroying rewarded adapter"];
    self.isDestroyed = YES;
    
    self.delegate = nil;
    self.isLoading = NO;
    self.isReady = NO;
}

@end

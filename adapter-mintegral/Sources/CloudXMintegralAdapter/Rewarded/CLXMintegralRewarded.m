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
        _playVideoMute = NO;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralRewarded"];
        
        [self.logger debug:[NSString stringWithFormat:@"Init - PlacementID:%@, UnitID:%@, BidID:%@", 
                           placementID, unitID, bidID]];
        
        // NOTE: MTGBidRewardAdManager is a SINGLETON - we don't create instances
        // We use [MTGBidRewardAdManager sharedInstance] for all operations
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
        // Apply mute setting before loading
        [MTGBidRewardAdManager sharedInstance].playVideoMute = self.playVideoMute;
        
        if (self.bidPayload && self.bidPayload.length > 0) {
            // Bidding flow - use singleton with bid token
            [[MTGBidRewardAdManager sharedInstance] loadVideoWithBidToken:self.bidPayload
                                                              placementId:self.placementID
                                                                   unitId:self.unitID
                                                                 delegate:self];
        } else {
            // Non-bidding flow - load without bid token
            [[MTGBidRewardAdManager sharedInstance] loadVideoWithPlacementId:self.placementID
                                                                      unitId:self.unitID
                                                                    delegate:self];
        }
    });
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL ready = [[MTGBidRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId:_placementID unitId:_unitID];
    
    if (ready) {
        [self.logger info:@"Showing rewarded"];
        
        // Retrieve creative ID before showing
        _creativeID = [[MTGBidRewardAdManager sharedInstance] getCreativeIdWithUnitId:_unitID];
        if (_creativeID) {
            [self.logger debug:[NSString stringWithFormat:@"Creative ID: %@", _creativeID]];
        }
        
        if ([self.delegate respondsToSelector:@selector(didShowWithRewarded:)]) {
            [self.delegate didShowWithRewarded:self];
        }
        
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
    // Ad has loaded and video has been downloaded
    [self.logger info:@"Loaded successfully (video downloaded)"];
    _isLoading = NO;
    
    // Retrieve creative ID
    _creativeID = [[MTGBidRewardAdManager sharedInstance] getCreativeIdWithUnitId:unitId];
    
    if ([self.delegate respondsToSelector:@selector(didLoadWithRewarded:)]) {
        [self.delegate didLoadWithRewarded:self];
    }
}

- (void)onAdLoadSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    // Ad has loaded but video still needs to be downloaded
    [self.logger debug:@"Ad loaded, video downloading..."];
}

- (void)onVideoAdLoadFailed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId error:(NSError *)error {
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

#pragma mark - MTGRewardAdShowDelegate

- (void)onVideoAdShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger info:@"Did present"];
    
    if ([self.delegate respondsToSelector:@selector(impressionWithRewarded:)]) {
        [self.delegate impressionWithRewarded:self];
    }
}

- (void)onVideoAdShowFailed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId withError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    
    NSError *mappedError = [CLXMintegralErrorHandler handleNetworkError:error
                                                             withLogger:self.logger
                                                                context:@"Rewarded Show"
                                                            placementID:_placementID];
    
    if ([self.delegate respondsToSelector:@selector(didFailToShowWithRewarded:error:)]) {
        [self.delegate didFailToShowWithRewarded:self error:mappedError];
    }
}

- (void)onVideoAdClicked:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger info:@"Did click"];
    
    if ([self.delegate respondsToSelector:@selector(clickWithRewarded:)]) {
        [self.delegate clickWithRewarded:self];
    }
}

- (void)onVideoAdDismissed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId withConverted:(BOOL)converted withRewardInfo:(nullable MTGRewardAdInfo *)rewardInfo {
    [self.logger info:[NSString stringWithFormat:@"Did dismiss - Converted:%d", converted]];
    
    if (converted && [self.delegate respondsToSelector:@selector(rewardedWithRewarded:)]) {
        [self.delegate rewardedWithRewarded:self];
    }
    
    if ([self.delegate respondsToSelector:@selector(didCloseWithRewarded:)]) {
        [self.delegate didCloseWithRewarded:self];
    }
}

- (void)onVideoAdDidClosed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"Video completed"];
}

- (void)onVideoPlayCompleted:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"Video play completed"];
}

- (void)onVideoEndCardShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"End card shown"];
}

@end


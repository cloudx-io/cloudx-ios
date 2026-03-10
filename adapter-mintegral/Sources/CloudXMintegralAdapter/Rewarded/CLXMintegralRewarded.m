#import "CLXMintegralRewarded.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import "CLXMintegralErrorHandler.h"
#import "CLXMintegralInitializer.h"

@interface CLXMintegralRewarded ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign, readwrite) BOOL isReady;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, copy) NSString *unitID;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy, nullable) NSString *creativeID;
@property (nonatomic, assign) BOOL playVideoMute;
@property (nonatomic, assign) BOOL grantedReward;
@property (nonatomic, assign) NSInteger rewardAmount;
@property (nonatomic, copy, nullable) NSString *rewardName;
@end

@implementation CLXMintegralRewarded

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                     playVideoMute:(BOOL)playVideoMute
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
        _playVideoMute = playVideoMute;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralRewarded"];
        _isReady = NO;
        
        [self.logger debug:[NSString stringWithFormat:@"Init - Placement: %@, PlacementID:%@, UnitID:%@", adUnitName ?: @"(unknown)", placementID, unitID]];
    }
    return self;
}

- (void)load {
    if (!_unitID || _unitID.length == 0) {
        NSString *adUnitContext = _adUnitName ? [NSString stringWithFormat:@" for ad unit '%@'", _adUnitName] : @"";
        NSString *errorMessage = [NSString stringWithFormat:@"Mintegral unit ID is empty%@. "
                                  "Make sure to configure the Mintegral unit ID in your CloudX dashboard under Ad Unit Settings > Mintegral.",
                                  adUnitContext];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInvalidServerExtras
                                     description:errorMessage];
        [self.logger error:error.localizedDescription];
        [self.delegate didFailToLoadWithRewarded:self error:error];
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Loading rewarded - Placement: %@, PlacementID:%@, UnitID:%@", _adUnitName ?: @"(unknown)", _placementID, _unitID]];

    if (self.bidPayload && self.bidPayload.length > 0) {
        [MTGBidRewardAdManager sharedInstance].playVideoMute = self.playVideoMute;
        [[MTGBidRewardAdManager sharedInstance] loadVideoWithBidToken:self.bidPayload
                                                          placementId:self.placementID
                                                               unitId:self.unitID
                                                             delegate:self];
    } else {
        [MTGRewardAdManager sharedInstance].playVideoMute = self.playVideoMute;

        if ([[MTGRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId:self.placementID unitId:self.unitID]) {
            _creativeID = [[MTGRewardAdManager sharedInstance] getCreativeIdWithUnitId:self.unitID];
            _isReady = YES;
            [self.delegate didLoadWithRewarded:self];
            return;
        }

        [[MTGRewardAdManager sharedInstance] loadVideoWithPlacementId:self.placementID
                                                               unitId:self.unitID
                                                             delegate:self];
    }
}

- (void)showFromViewController:(UIViewController *)viewController {
    BOOL isBidding = self.bidPayload && self.bidPayload.length > 0;
    BOOL ready = NO;

    if (isBidding) {
        ready = self.isReady && [[MTGBidRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId:_placementID unitId:_unitID];
    } else {
        ready = self.isReady && [[MTGRewardAdManager sharedInstance] isVideoReadyToPlayWithPlacementId:_placementID unitId:_unitID];
    }

    if (ready) {
        [self.logger info:[NSString stringWithFormat:@"Showing rewarded (%@)", isBidding ? @"bidding" : @"waterfall"]];

        if (isBidding) {
            [[MTGBidRewardAdManager sharedInstance] showVideoWithPlacementId:self.placementID
                                                                      unitId:self.unitID
                                                                withRewardId:nil
                                                                      userId:nil
                                                                    delegate:self
                                                              viewController:viewController];
        } else {
            [[MTGRewardAdManager sharedInstance] showVideoWithPlacementId:self.placementID
                                                                   unitId:self.unitID
                                                             withRewardId:nil
                                                                   userId:nil
                                                                 delegate:self
                                                           viewController:viewController];
        }
    } else {
        [self.logger error:@"Cannot show - ad not ready"];
        NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterAdNotReady
                                     description:@"Rewarded ad not ready"];
        [self.delegate didFailToShowWithRewarded:self error:error];
    }
}

#pragma mark - MTGRewardAdLoadDelegate

- (void)onVideoAdLoadSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    BOOL isBidding = self.bidPayload && self.bidPayload.length > 0;
    [self.logger info:[NSString stringWithFormat:@"Rewarded loaded successfully (%@)", isBidding ? @"bidding" : @"waterfall"]];
    _isReady = YES;

    if (isBidding) {
        _creativeID = [[MTGBidRewardAdManager sharedInstance] getCreativeIdWithUnitId:unitId];
    } else {
        _creativeID = [[MTGRewardAdManager sharedInstance] getCreativeIdWithUnitId:unitId];
    }

    [self.delegate didLoadWithRewarded:self];
}

- (void)onAdLoadSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"Ad loaded, video downloading..."];
}

- (void)onVideoAdLoadFailed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId error:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
    _isReady = NO;
    CLXError *mappedError = [CLXMintegralErrorHandler toCloudXError:error];
    [self.delegate didFailToLoadWithRewarded:self error:mappedError];
}

#pragma mark - MTGRewardAdShowDelegate

- (void)onVideoAdShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger info:@"Rewarded displayed"];
    [self.delegate didShowWithRewarded:self];
    [self.delegate impressionWithRewarded:self];
}

- (void)onVideoAdShowFailed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId withError:(NSError *)error {
    [self.logger error:[NSString stringWithFormat:@"Failed to show: %@", error.localizedDescription]];
    CLXError *mappedError = [CLXMintegralErrorHandler toCloudXError:error];
    [self.delegate didFailToShowWithRewarded:self error:mappedError];
}

- (void)onVideoAdClicked:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger info:@"Rewarded clicked"];
    [self.delegate clickWithRewarded:self];
}

- (void)onVideoAdDismissed:(nullable NSString *)placementId
                    unitId:(nullable NSString *)unitId
             withConverted:(BOOL)converted
            withRewardInfo:(nullable MTGRewardAdInfo *)rewardInfo {
    [self.logger info:[NSString stringWithFormat:@"Rewarded dismissed - converted:%d", converted]];
    self.grantedReward = converted;
    self.rewardAmount = rewardInfo ? rewardInfo.rewardAmount : 0;
    self.rewardName = rewardInfo ? [rewardInfo.rewardName copy] : nil;
}

- (void)onVideoAdDidClosed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger info:@"Rewarded closed"];
    _isReady = NO;

    BOOL shouldReward = self.grantedReward;
    NSInteger rewardAmount = self.rewardAmount;
    NSString *rewardName = self.rewardName;

    self.grantedReward = NO;
    self.rewardAmount = 0;
    self.rewardName = nil;

    if (shouldReward) {
        if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:amount:label:)]) {
            [self.delegate userRewardWithRewarded:self amount:rewardAmount label:rewardName];
        } else if ([self.delegate respondsToSelector:@selector(userRewardWithRewarded:)]) {
            [self.delegate userRewardWithRewarded:self];
        }
    }

    [self.delegate didCloseWithRewarded:self];
}

- (void)onVideoPlayCompleted:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"Video play completed"];
}

- (void)onEndcardShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
    [self.logger debug:@"End card shown"];
}

#pragma mark - Lifecycle

- (void)destroy {
    [self.logger debug:@"Destroying rewarded adapter"];
    self.delegate = nil;
    self.isReady = NO;
}

@end

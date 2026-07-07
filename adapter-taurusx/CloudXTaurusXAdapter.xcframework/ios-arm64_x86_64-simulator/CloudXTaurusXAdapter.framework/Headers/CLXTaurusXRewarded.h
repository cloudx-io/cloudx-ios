#import <CloudXCore/CLXAdapterRewarded.h>
@import TaurusxAdsSDK;

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXRewarded : CLXAdapterRewarded <TaurusXRewardedDelegate>

- (instancetype)initWithPlacementID:(nullable NSString *)placementID
                             payload:(nullable NSString *)payload;

@end

NS_ASSUME_NONNULL_END

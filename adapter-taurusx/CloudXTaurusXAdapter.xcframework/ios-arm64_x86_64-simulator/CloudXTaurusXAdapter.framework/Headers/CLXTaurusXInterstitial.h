#import <CloudXCore/CLXAdapterInterstitial.h>
@import TaurusxAdsSDK;

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXInterstitial : CLXAdapterInterstitial <TaurusXInterstitialDelegate>

- (instancetype)initWithPlacementID:(nullable NSString *)placementID
                             payload:(nullable NSString *)payload;

@end

NS_ASSUME_NONNULL_END

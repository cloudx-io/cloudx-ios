#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXBannerType.h>
@import TaurusxAdsSDK;

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXAdView : CLXAdapterAdView <TaurusXBannerDelegate>

- (instancetype)initWithPlacementID:(nullable NSString *)placementID
                             payload:(nullable NSString *)payload
                                type:(CLXBannerType)type;

@end

NS_ASSUME_NONNULL_END

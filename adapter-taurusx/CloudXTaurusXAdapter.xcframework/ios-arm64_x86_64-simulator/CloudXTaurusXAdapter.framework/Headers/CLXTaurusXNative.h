#import <CloudXCore/CLXAdapterNative.h>
@import TaurusxAdsSDK;

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXNative : CLXAdapterNative <TaurusXNativeDelegate>

- (instancetype)initWithPlacementID:(nullable NSString *)placementID
                             payload:(nullable NSString *)payload;

@end

NS_ASSUME_NONNULL_END

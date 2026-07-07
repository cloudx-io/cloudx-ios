#import <CloudXCore/CLXNativeAd.h>
@import TaurusxAdsSDK;

NS_ASSUME_NONNULL_BEGIN

@interface CLXTaurusXNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) TaurusXNative *native;

- (instancetype)initWithNative:(TaurusXNative *)native
                    nativeData:(TaurusXNativeData *)nativeData
                     nativeView:(nullable UIView *)nativeView;

@end

NS_ASSUME_NONNULL_END

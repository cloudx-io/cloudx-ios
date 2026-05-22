//
//  CLXInMobiNativeAd.h
//  CloudXInMobiAdapter
//

#import <InMobiSDK/InMobiSDK-Swift.h>
#import <CloudXCore/CLXNativeAd.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Concrete `CLXNativeAd` wrapping an InMobi `IMNative` SDK handle.
 *
 * Registers the native ad views via `IMNativeViewDataBuilder` in
 * `prepareForInteractionClickableViews:withContainer:`.
 */
@interface CLXInMobiNativeAd : CLXNativeAd

@property (nonatomic, strong, nullable) IMNative *imNative;

- (instancetype)initWithIMNative:(IMNative *)imNative
            localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END

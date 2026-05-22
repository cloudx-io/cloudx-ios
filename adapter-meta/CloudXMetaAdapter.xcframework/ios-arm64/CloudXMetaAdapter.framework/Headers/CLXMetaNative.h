/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Meta native adapter. Conforms to both `FBNativeAdDelegate` and `FBNativeBannerAdDelegate`
 * so a single adapter instance can host either concrete class returned by Meta's native
 * factory method (`+[FBNativeAdBase nativeAdWithPlacementId:bidPayload:error:]`).
 *
 * Branching is driven by `isKindOfClass:` at each delegate entry point and at register time.
 */
@interface CLXMetaNative : CLXAdapterNative <FBNativeAdDelegate, FBNativeBannerAdDelegate>

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                  bidExpirationMs:(NSInteger)bidExpirationMs
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters;

@end

NS_ASSUME_NONNULL_END

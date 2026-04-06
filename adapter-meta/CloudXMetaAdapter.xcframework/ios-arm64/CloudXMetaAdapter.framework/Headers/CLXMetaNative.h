/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaNative : NSObject <FBNativeAdDelegate, CLXAdapterNative>

@property (nonatomic, strong, nullable) id<CLXAdapterNativeDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                  bidExpirationMs:(NSInteger)bidExpirationMs
              localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                          delegate:(id<CLXAdapterNativeDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

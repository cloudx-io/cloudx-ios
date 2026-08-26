//
//  CLXGamNativeAdMapper.h
//  CloudXGAMPrebid
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "CLXGamNativeGamBridge.h"

@class CLXNativeAd;

NS_ASSUME_NONNULL_BEGIN

/**
 * Maps a loaded CloudX native ad's assets onto the GAD mediation native ad
 * contract. Mirrors the Android CxNativeAdMapper: CloudX owns click and
 * impression handling, so both are marked handled here and forwarded through
 * the impression/click blocks the custom event supplies.
 *
 * Also serves as the facade's GAM click bridge, so a CloudX-originated click
 * reaches GAM's event delegate through the same block.
 */
@interface CLXGamNativeAdMapper : NSObject <GADMediationNativeAd, CLXGamNativeGamBridge>

- (instancetype)initWithNativeAd:(CLXNativeAd *)nativeAd
                    onImpression:(void (^)(void))onImpression
                         onClick:(void (^)(void))onClick NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXNativeTemplate.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAd;
@class CLXNativeAd;
@class CLXNativeAdView;
@class CLXError;
@class CLXSDKConfigAdUnit;
@class CLXConfigImpressionModel;
@class CLXBidAdSourceResponse;
@class CLXBidResponseBid;

@protocol CLXAdEventReporting;
@class CLXBidTokenSource;
@class CLXAdapterNativeFactory;
@protocol CLXPublisherNativeDelegate;

@interface CLXPublisherNative : NSObject

@property (nonatomic, weak, nullable) id<CLXPublisherNativeDelegate> publisherDelegate;
@property (nonatomic, readonly) CLXNativeTemplate nativeType;
@property (nonatomic, copy, nullable) NSString *adUnitId;
@property (nonatomic, copy, nullable) NSString *adUnitName;
@property (nonatomic, strong, nullable, readonly) CLXBidAdSourceResponse *lastBidResponse;

- (instancetype)initWithAdUnit:(nullable CLXSDKConfigAdUnit *)adUnit
                        userID:(NSString *)userID
                   publisherID:(NSString *)publisherID
                    nativeType:(CLXNativeTemplate)nativeType
                      impModel:(nullable CLXConfigImpressionModel *)impModel
                   adFactories:(NSDictionary<NSString *, CLXAdapterNativeFactory *> *)adFactories
               bidTokenSources:(NSDictionary<NSString *, CLXBidTokenSource *> *)bidTokenSources
             bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
              reportingService:(id<CLXAdEventReporting>)reportingService;

- (void)load;
- (void)destroyCurrentAd;
- (void)destroy;

@property (nonatomic, copy, nullable) NSString *requestedAdUnitId;
@property (nonatomic, strong, nullable) CLXError *deferredError;
@property (nonatomic, copy, nullable) NSString *publisherPlacement;
@property (nonatomic, copy, nullable) NSString *publisherCustomData;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *localExtraParameters;
@property (nonatomic, assign, readonly) BOOL isReady;

@end

@protocol CLXPublisherNativeDelegate <NSObject>

- (void)publisherNative:(CLXPublisherNative *)publisherNative didLoadNativeAd:(CLXNativeAd *)nativeAd forAd:(CLXAd *)ad;
- (void)publisherNative:(CLXPublisherNative *)publisherNative didFailToLoadWithError:(CLXError *)error;
- (void)publisherNative:(CLXPublisherNative *)publisherNative didDisplayAd:(CLXAd *)ad;
- (void)publisherNative:(CLXPublisherNative *)publisherNative didClickAd:(CLXAd *)ad;
- (void)publisherNative:(CLXPublisherNative *)publisherNative didPayRevenueForAd:(CLXAd *)ad;

@optional
- (void)publisherNative:(CLXPublisherNative *)publisherNative didExpireAd:(CLXAd *)ad;
/** User completed AdChoices opt-out (reported/hid the ad). The ad creative is invalidated. */
- (void)publisherNative:(CLXPublisherNative *)publisherNative didCloseAd:(CLXAd *)ad;

@end

NS_ASSUME_NONNULL_END

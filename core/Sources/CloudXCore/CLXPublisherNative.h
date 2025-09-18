/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPublisherNative.h
 * @brief Publisher native ad implementation
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXNativeAdView.h>


NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdEventReporting;
@class CLXEnvironmentConfig;

/**
 * CLXPublisherNative implements the CLXNative protocol and handles native ad loading,
 * bidding, and lifecycle management.
 */
@interface CLXPublisherNative : NSObject <CLXNative>

/**
 * Flag to indicate whether to suspend preloading when the ad is not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * Delegate for native ad events. Supports both old adapter methods and new CLXAd methods.
 */
@property (nonatomic, weak, nullable) id<CLXNativeDelegate, CLXAdapterNativeDelegate> delegate;

/**
 * The type of native ad template.
 */
@property (nonatomic, readonly) CLXNativeTemplate nativeType;



/**
 * Initializes a new CLXPublisherNative with the given parameters.
 * @param viewController The view controller where the native ad will be displayed
 * @param placement The placement configuration
 * @param userID The user ID
 * @param publisherID The publisher ID
 * @param suspendPreloadWhenInvisible Whether to suspend preloading when not visible
 * @param delegate The delegate to receive events
 * @param nativeType The type of native ad template
 * @param waterfallMaxBackOffTime Maximum backoff time for waterfall
 * @param impModel The impression model
 * @param adFactories Dictionary of native ad factories
 * @param bidTokenSources Dictionary of bid token sources
 * @param bidRequestTimeout Bid request timeout
 * @param reportingService The reporting service
 * @return Initialized CLXPublisherNative instance
 */
- (instancetype)initWithViewController:(UIViewController *)viewController
                             placement:(CLXSDKConfigPlacement *)placement
                                userID:(NSString *)userID
                           publisherID:(NSString *)publisherID
              suspendPreloadWhenInvisible:(BOOL)suspendPreloadWhenInvisible
                               delegate:(nullable id<CLXNativeDelegate, CLXAdapterNativeDelegate>)delegate
                             nativeType:(CLXNativeTemplate)nativeType
                   waterfallMaxBackOffTime:(NSTimeInterval)waterfallMaxBackOffTime
                                  impModel:(CLXConfigImpressionModel *)impModel
                              adFactories:(NSDictionary<NSString *, id<CLXAdapterNativeFactory>> *)adFactories
                           bidTokenSources:(NSDictionary<NSString *, id<CLXBidTokenSource>> *)bidTokenSources
                        bidRequestTimeout:(NSTimeInterval)bidRequestTimeout
                         reportingService:(id<CLXAdEventReporting>)reportingService;

@end

NS_ASSUME_NONNULL_END 
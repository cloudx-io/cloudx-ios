/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXNativeAdView.h
 * @brief Native ad view class
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXBaseAd.h>
#import <CloudXCore/CLXNativeDelegate.h>
#import <CloudXCore/CLXAdapterNative.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXNative;

/**
 * The native ad view. Add this object to your view hierarchy to display native ads.
 */
@interface CLXNativeAdView : UIView <CLXAd, CLXAdapterNativeDelegate>

/**
 * Delegate for the native ad view to notify about ad events.
 */
@property (nonatomic, weak, nullable) id<CLXNativeDelegate> delegate;

/**
 * Flag to indicate if the native ad is ready to be shown.
 */
@property (nonatomic, assign, readwrite) BOOL isReady;

/**
 * A boolean indicating whether to suspend preloading the ad when it's not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * Initializes a new CloudXNativeAdView with the given native, type, and delegate.
 * @param native The native instance
 * @param type The native template type
 * @param delegate The delegate to receive events
 * @return Initialized native ad view
 */
- (instancetype)initWithNative:(id<CLXNative>)native 
                         type:(NSInteger)type 
                     delegate:(nullable id<CLXNativeDelegate>)delegate;

/**
 * Starts loading the native ad
 */
- (void)load;

/**
 * Destroys the native ad and release all resources
 */
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 
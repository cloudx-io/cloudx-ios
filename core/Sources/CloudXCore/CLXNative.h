/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXNative.h
 * @brief Native ad protocol
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdFormat.h>
#import <CloudXCore/CLXNativeTemplate.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterNativeDelegate;

/**
 * CloudXNative is a protocol for native ads in the CloudX SDK.
 * Defines native-specific properties and functionality.
 */
@protocol CLXNative <CLXAdFormat>

/**
 * Flag to indicate whether to suspend preloading when the ad is not visible.
 */
@property (nonatomic, assign) BOOL suspendPreloadWhenInvisible;

/**
 * Delegate for native ad events.
 */
@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> delegate;

/**
 * The type of native ad template.
 */
@property (nonatomic, readonly) CLXNativeTemplate nativeType;

@end

NS_ASSUME_NONNULL_END 
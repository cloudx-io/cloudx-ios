/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXNativeDelegate.h
 * @brief Protocol for Native ad delegates
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for Native ad delegates.
 * Extends BaseAdDelegate to provide native ad specific delegate methods.
 *
 * @note Threading contract: see `CLXAdDelegate`. All inherited callbacks
 * deliver on the main queue and may fire inline relative to the SDK call
 * that triggered them. The publisher-facing fan-out methods declared by
 * `CLXPublisherNativeDelegate` (didLoadNativeAd:forAd:, didDisplayAd:,
 * didExpireAd:, didCloseAd:, didFailToLoadWithError:) follow the same
 * contract.
 */
@protocol CLXNativeDelegate <CLXAdDelegate>

@end

NS_ASSUME_NONNULL_END 
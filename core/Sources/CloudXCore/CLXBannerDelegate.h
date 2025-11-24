/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBannerDelegate.h
 * @brief Banner ad delegate protocol
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdDelegate.h>

@class CloudXBanner;

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for Banner ad delegates.
 * Extends CLXAdDelegate with banner-specific callbacks.
 */
@protocol CLXBannerDelegate <CLXAdDelegate>

@optional

/**
 * Called when the banner ad expands.
 * @param ad The banner ad that expanded
 */
- (void)didExpandAd:(CLXAd *)ad NS_SWIFT_NAME(didExpand(_:));

/**
 * Called when the banner ad collapses.
 * @param ad The banner ad that collapsed
 */
- (void)didCollapseAd:(CLXAd *)ad NS_SWIFT_NAME(didCollapse(_:));

@end

NS_ASSUME_NONNULL_END 
/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXFullscreenAd.h
 * @brief Fullscreen ad protocol
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXBaseAd.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudXFullscreenAd is a base protocol for fullscreen ad types in the CloudX SDK.
 * It inherits from CloudXAd and adds the ability to show ads from a view controller.
 */
@protocol CLXFullscreenAd <CLXAd>

/**
 * Shows the fullscreen ad from the provided view controller.
 * @param viewController The view controller from which to show the ad
 */
- (void)showFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END 
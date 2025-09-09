/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXBaseAd.h
 * @brief Base protocols for all ad types and delegates
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Base protocol for all ad types.
 */
@protocol CLXAd <NSObject>

/**
 * Starts loading ad
 */
- (void)load;

/**
 * Destroys the ad and releases all resources
 */
- (void)destroy;

/**
 * Checks if the ad is ready to be shown
 */
- (BOOL)isReady;

@end



NS_ASSUME_NONNULL_END 
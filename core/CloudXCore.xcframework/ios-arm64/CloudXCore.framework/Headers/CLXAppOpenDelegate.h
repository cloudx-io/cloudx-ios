/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAppOpenDelegate.h
 * @brief App open ad delegate protocol
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXFullscreenAdDelegate.h>

@class CLXAppOpen;

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol CLXAppOpenDelegate
 * @brief Delegate protocol for app open ad events
 *
 * Extends CLXFullscreenAdDelegate with app-open-specific callbacks.
 */
@protocol CLXAppOpenDelegate <CLXFullscreenAdDelegate>

@end

NS_ASSUME_NONNULL_END

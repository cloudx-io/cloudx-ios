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
 */
@protocol CLXNativeDelegate <CLXAdDelegate>

@end

NS_ASSUME_NONNULL_END 
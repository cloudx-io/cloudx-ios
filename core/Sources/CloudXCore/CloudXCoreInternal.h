/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXCoreInternal.h
 * @brief Internal methods for CloudXCore - not exposed in public API
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCoreAPI.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Internal extension of CloudXCore for SDK-internal use only
 */
@interface CloudXCore (Internal)

/**
 * Track SDK errors for analytics reporting
 * @param error The error to track
 * @discussion Internal method used by CLXErrorReporter - not part of public API
 */
+ (void)trackSDKError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END


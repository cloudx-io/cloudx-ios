/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXVersion.h
 * @brief CloudX SDK version information
 * @details This file contains the SDK version constant. It is automatically updated
 *          by the release process based on Git tags (e.g., v1.1.58-core).
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The CloudX SDK version string
 * Format: MAJOR.MINOR.PATCH (e.g., "1.1.58")
 * This constant is automatically updated during the release process
 */
FOUNDATION_EXPORT NSString * const CLXSDKVersion;

NS_ASSUME_NONNULL_END


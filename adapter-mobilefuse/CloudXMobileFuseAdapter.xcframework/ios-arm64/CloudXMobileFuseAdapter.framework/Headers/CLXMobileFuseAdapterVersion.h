/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The CloudX MobileFuse Adapter version string.
 * Format: MAJOR.MINOR.PATCH (e.g., "1.0.0").
 * Used in the mediation identifier passed to MobileFuse on init:
 *   CLOUDX_{CoreSDKVersion}:{AdapterVersion}
 */
FOUNDATION_EXPORT NSString * const CLXMobileFuseAdapterVersion;

NS_ASSUME_NONNULL_END

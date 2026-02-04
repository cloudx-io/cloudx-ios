/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The CloudX Meta Adapter version string
 * Format: MAJOR.MINOR.PATCH (e.g., "1.1.34")
 * This constant is automatically updated during the release process.
 * Used in mediation identifier sent to Meta: CLOUDX_{SDKVersion}:{AdapterVersion}
 */
FOUNDATION_EXPORT NSString * const CLXMetaAdapterVersion;

NS_ASSUME_NONNULL_END


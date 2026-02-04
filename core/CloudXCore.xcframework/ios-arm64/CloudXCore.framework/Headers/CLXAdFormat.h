/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdFormat.h
 * @brief Ad format types for public API parity with Android CloudXAdFormat
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ad format types representing the different ad formats supported by CloudX SDK.
 * This enum provides public API parity with Android's CloudXAdFormat.
 */
typedef NS_ENUM(NSInteger, CLXAdFormat) {
    CLXAdFormatBanner = 0,
    CLXAdFormatMREC = 1,
    CLXAdFormatInterstitial = 2,
    CLXAdFormatRewarded = 3,
    CLXAdFormatNative = 4,
};

NS_ASSUME_NONNULL_END

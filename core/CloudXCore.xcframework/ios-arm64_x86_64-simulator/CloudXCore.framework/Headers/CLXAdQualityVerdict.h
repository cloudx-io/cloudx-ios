/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdQualityVerdict.h
 * @brief Immutable decision returned by an ad-quality gate.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Immutable decision returned by an ad-quality gate.
 *
 * A gate either allows an ad through (`+allow`) or vetoes it
 * (`+blockWithReason:`). The verdict is consumed by core, never by the
 * publisher. Core enforces the verdict's consequences (forward as loaded, or
 * route into the adapter-load-failure path) — the gate implementation only
 * produces the verdict.
 */
CLX_PUBLIC
@interface CLXAdQualityVerdict : NSObject

/** YES when the ad is allowed to surface to the publisher; NO when the gate vetoes it. */
@property (nonatomic, assign, readonly) BOOL allowed;

/**
 * The free-form reason the gate supplied when blocking, or nil when allowed
 * (or when the gate blocked without a reason). Copied at construction.
 */
@property (nonatomic, copy, readonly, nullable) NSString *reason;

/**
 * Convenience factory for an allow verdict. The ad surfaces to the publisher
 * as loaded.
 * @return A non-nil allow verdict with @c allowed == YES and @c reason == nil.
 */
+ (instancetype)allow NS_SWIFT_NAME(allow());

/**
 * Convenience factory for a block verdict. Core routes the ad into the existing
 * adapter-load-failure path with a @c CLXAdQualityError carrying this reason.
 * @param reason The free-form reason for the block, or nil. Copied.
 * @return A non-nil block verdict with @c allowed == NO.
 */
+ (instancetype)blockWithReason:(nullable NSString *)reason NS_SWIFT_NAME(block(reason:));

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

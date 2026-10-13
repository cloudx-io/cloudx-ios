/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdQualityError.h
 * @brief Error domain, code, and factory for ad-quality gate decisions.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error domain for ad-quality gate decisions.
 *
 * Surfaced to publishers through the standard load-failure callback
 * (`didFailToLoadAd:error:` / `publisherNative:didFailToLoadWithError:`) when the
 * registered ad-quality gate vetoes an ad. The error rides the existing
 * adapter-load-failure pipeline unchanged so waterfall / refresh / teardown
 * machinery runs identically to a network load failure — only the domain and
 * code distinguish a gate veto from a network failure.
 */
CLX_PUBLIC
extern NSString * const CLXAdQualityErrorDomain;

/**
 * Error codes under @c CLXAdQualityErrorDomain.
 */
typedef NS_ENUM(NSInteger, CLXAdQualityErrorCode) {
    /**
     * The registered ad-quality gate vetoed the ad before it was surfaced to the
     * publisher. The gate's free-form reason string (if supplied) is carried in
     * @c userInfo[CLXAdQualityErrorReasonKey].
     */
    CLXAdQualityErrorBlocked = 1,
};

/**
 * @c userInfo key for the block reason string supplied by the gate. Present only
 * when the gate provided a non-nil reason.
 */
CLX_PUBLIC
extern NSString * const CLXAdQualityErrorReasonKey;

/**
 * An error in the @c CLXAdQualityErrorDomain, produced when the ad-quality gate
 * blocks an ad.
 *
 * Subclasses @c CLXError so it rides the existing load-failure conversion path
 * (`+[CLXError errorFromError:withFallbackCode:]` returns CLXError subclasses
 * as-is) without being re-wrapped into @c CLXErrorDomain — the publisher
 * observes the ad-quality domain and code directly.
 */
CLX_PUBLIC
@interface CLXAdQualityError : CLXError

/**
 * Creates a blocked-error carrying the gate's reason (if any) in
 * @c userInfo[CLXAdQualityErrorReasonKey].
 * @param reason The free-form reason the gate supplied, or nil. Copied.
 * @return A non-nil @c CLXAdQualityError with code @c CLXAdQualityErrorBlocked.
 */
+ (instancetype)blockedErrorWithReason:(nullable NSString *)reason
    NS_SWIFT_NAME(blockedError(reason:));

@end

NS_ASSUME_NONNULL_END

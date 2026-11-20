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
 * When the registered ad-quality gate vetoes an ad, the standard load-failure
 * callback (`didFailToLoadAd:error:` / `publisherNative:didFailToLoadWithError:`)
 * receives a @c CLXErrorDomain error with code @c CLXErrorCodeAdQualityBlocked
 * (307) whose underlying error (@c NSUnderlyingErrorKey) is in this domain.
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
 * The publisher receives it as the underlying error of a @c CLXErrorDomain
 * @c CLXErrorCodeAdQualityBlocked (307) load failure.
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

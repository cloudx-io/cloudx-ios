/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXNetworkAdObjectProviding.h
 * @brief Narrow, one-method protocol an adapter may adopt to hand an ad-quality
 *        engine the partner SDK's own ad object instead of the CloudX wrapper.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Optional conformance for adapters that can expose the underlying partner SDK
 * ad object for ad-quality analysis.
 *
 * @brief Narrow, one-method protocol an adapter may adopt to hand an ad-quality
 *        engine the partner SDK's own ad object instead of the CloudX wrapper.
 *
 * @discussion Some ad-quality engines validate the concrete ad class and reject
 * a mediation wrapper, expecting the partner SDK's own ad instance instead. An
 * adapter that can expose that underlying object conforms to this protocol so
 * the ad-quality coordinator substitutes it for the wrapper at request
 * construction time. Adapters that cannot reach a meaningful partner object
 * simply do not conform, and the coordinator falls back to the wrapper — no
 * adapter is forced to implement a no-op (Interface Segregation).
 */
@protocol CLXNetworkAdObjectProviding <NSObject>

/**
 * @brief The underlying partner SDK ad object to forward to an ad-quality engine.
 *
 * @return The partner SDK ad object, or nil when no such object is available at
 *         this point. A nil return is meaningful: it signals the coordinator to
 *         fall back to the CloudX wrapper object rather than substitute nothing.
 *         The returned object is strongly retained for the duration of the
 *         ad-quality evaluation — the request holds it via its strong @c adObject
 *         property, and the coordinator retains the request while pending.
 */
- (nullable NSObject *)networkAdObjectForAdQuality;

@end

NS_ASSUME_NONNULL_END

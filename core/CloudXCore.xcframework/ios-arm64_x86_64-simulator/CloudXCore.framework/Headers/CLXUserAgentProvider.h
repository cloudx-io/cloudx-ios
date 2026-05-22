/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Resolves and caches the device User-Agent string for wire payloads.
 *
 * WKWebView's `valueForKey:@"userAgent"` is the canonical iOS source — it
 * returns the same UA the system uses for HTTP requests, matching what
 * publishers and DSPs expect to see on the wire. The resolve is main-thread
 * only and triggers WebKit Chromium initialization (~50–150ms cold start).
 *
 * The UA is process-stable, so the provider warms once via prepareWithCompletion:
 * during SDK init and serves the cached value to all downstream consumers
 * (init request, bid request, telemetry envelope). Callers reading userAgent
 * before prepare completes (or when WKWebView produces an empty value) get an
 * empty string rather than a blocking resolve — this avoids deadlocking the
 * main thread if init is racing with an early consumer, and callers that
 * serialize the value can treat empty as "omit deviceUA from the wire"
 * instead of faking a value that misrepresents the device.
 */
@interface CLXUserAgentProvider : NSObject

/** Process-wide singleton. */
+ (instancetype)shared;

/**
 * Resolves the WKWebView User-Agent on the main thread and caches the result.
 * Safe to call from any thread; completion fires on a background queue once
 * the cache is populated. Calling more than once is a no-op after the first
 * successful resolve — completion fires immediately with the cached value.
 *
 * @param completion Optional callback fired once the cache is warm.
 */
- (void)prepareWithCompletion:(nullable void (^)(NSString *userAgent))completion;

/**
 * Returns the cached User-Agent if prepare has completed, otherwise an empty
 * string. Never returns nil. Safe to call from any thread. Callers that
 * serialize the value should treat an empty result as "omit deviceUA from the
 * wire" — see CLXSDKBlockProvider for the canonical consumer.
 */
- (NSString *)userAgent;

@end

NS_ASSUME_NONNULL_END

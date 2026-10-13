/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Resolves and caches the device User-Agent string for wire payloads.
 *
 * The value comes from WKWebView's `userAgent`, the same string the system
 * uses for HTTP requests. The resolve runs on the main thread.
 *
 * The last resolved value is saved and served from the next launch until that
 * launch resolves again. `userAgent` never resolves: it returns the cached
 * value or an empty string, and callers that serialize it treat empty as
 * "omit deviceUA from the wire".
 */
@interface CLXUserAgentProvider : NSObject

/** Process-wide singleton — the only supported entry point for production callers. */
+ (instancetype)shared;

/// Direct construction is unsupported. Use `+shared`. (Tests construct
/// instances via the internal initializer in CLXUserAgentProvider+Internal.h.)
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 * Resolves the WKWebView User-Agent on the main thread, caches it, and saves it
 * when it differs from the saved value. The first call in a process resolves
 * even when a saved value exists; after a successful resolve, later calls
 * complete with the cached value without resolving. Safe to call from any
 * thread; completion fires on a background queue.
 *
 * @param completion Optional callback fired with the resolved value, or an empty
 *   string if the resolve produced nothing in time.
 */
- (void)prepareWithCompletion:(nullable void (^)(NSString *userAgent))completion;

/**
 * Returns the cached User-Agent (the saved value until this process resolves),
 * or an empty string when none is known. Never resolves and never returns nil.
 * Safe to call from any thread. Callers that serialize the value should treat
 * an empty result as "omit deviceUA from the wire" — see CLXSDKBlockProvider
 * for the canonical consumer.
 */
- (NSString *)userAgent;

@end

NS_ASSUME_NONNULL_END

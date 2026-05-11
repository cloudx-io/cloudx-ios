#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSession (CloudX)

+ (NSURLSession *)cloudxSession;

/** @brief Gzip-compresses the given data. Returns nil if input is nil or empty. */
+ (nullable NSData *)clx_gzipData:(nullable NSData *)data;

/**
 * @brief Gzip-compresses @c body and installs it on @c request with @c Content-Encoding: gzip.
 *
 * Single call site for the CloudX "always gzip CloudX-owned POST bodies" policy. On gzip
 * failure or empty input, the raw body is installed and no encoding header is set, so the
 * request still goes out unchanged rather than failing.
 *
 * @param body Raw request body. Nil or empty is a no-op.
 * @param request Target request; @c HTTPBody is overwritten and @c Content-Encoding may be set.
 */
+ (void)clx_applyGzipBody:(nullable NSData *)body
                toRequest:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END 
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSession (CloudX)

+ (NSURLSession *)cloudxSession;

/** @brief Gzip-compresses the given data. Returns nil if input is nil or empty. */
+ (nullable NSData *)clx_gzipData:(nullable NSData *)data;

@end

NS_ASSUME_NONNULL_END 
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Geo API responsible for fetching geo headers from remote endpoint.
 * Pure HTTP layer - no processing logic.
 */
@interface CLXGeoApi : NSObject

- (instancetype)initWithUrl:(NSString *)url;
- (instancetype)initWithUrl:(NSString *)url session:(NSURLSession *)session userDefaults:(NSUserDefaults *)userDefaults;

/**
 * Fetches raw geo headers from the configured endpoint.
 * Makes an HTTP GET request with 5s timeout.
 * @param completion Completion handler with headers dictionary or error
 */
- (void)fetchGeoHeaders:(void(^)(NSDictionary<NSString *, NSString *> * _Nullable headers, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END

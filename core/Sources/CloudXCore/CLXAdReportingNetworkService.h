#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXAdReportingNetworkService : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL urlSession:(NSURLSession *)urlSession;

- (void)trackNUrlWithPrice:(double)price nUrl:(nullable NSString *)nUrl completion:(void (^)(BOOL success, NSError * _Nullable error))completion;
- (void)trackLUrlWithLUrl:(nullable NSString *)lUrl;
- (void)rillTrackingWithActionString:(NSString *)urlString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString error:(NSError **)error;
- (void)metricsTrackingWithActionString:(NSString *)actionString error:(NSError **)error;
- (void)geoHeadersWithURLString:(NSString *)fullURL
                         extras:(NSDictionary<NSString *, NSString *> *)extras;

@end

NS_ASSUME_NONNULL_END 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXAdReportingNetworkService : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL urlSession:(NSURLSession *)urlSession;

- (void)trackImpressionWithBidID:(NSString *)bidID error:(NSError **)error;
- (void)trackWinWithBidID:(NSString *)bidID error:(NSError **)error;
- (void)trackNUrlWithPrice:(double)price nUrl:(nullable NSString *)nUrl error:(NSError **)error;
- (void)trackLUrlWithLUrl:(nullable NSString *)lUrl;
- (void)rillTrackingWithActionString:(NSString *)urlString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString error:(NSError **)error;
- (void)metricsTrackingWithActionString:(NSString *)actionString error:(NSError **)error;
- (void)geoHeadersWithURLString:(NSString *)fullURL
                         extras:(NSDictionary<NSString *, NSString *> *)extras;

@end

NS_ASSUME_NONNULL_END 

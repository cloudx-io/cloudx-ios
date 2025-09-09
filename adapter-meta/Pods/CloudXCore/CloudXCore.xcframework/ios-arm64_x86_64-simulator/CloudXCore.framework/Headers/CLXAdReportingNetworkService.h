#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXAdReportingNetworkService : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL urlSession:(NSURLSession *)urlSession;

- (void)trackImpressionWithBidID:(NSString *)bidID error:(NSError **)error;
- (void)trackWinWithBidID:(NSString *)bidID error:(NSError **)error;
- (void)trackNUrlWithPrice:(double)price nUrl:(nullable NSString *)nUrl error:(NSError **)error;
- (void)rillTrackingWithActionString:(NSString *)urlString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString error:(NSError **)error;
- (void)geoHeadersWithURLString:(NSString *)fullURL
                         extras:(NSDictionary<NSString *, NSString *> *)extras;
                      //completion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END 

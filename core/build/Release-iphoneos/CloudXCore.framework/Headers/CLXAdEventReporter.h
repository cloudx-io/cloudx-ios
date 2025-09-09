#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdEventReporting <NSObject>
- (void)impressionWithBidID:(NSString *)bidID;
- (void)winWithBidID:(NSString *)bidID;
- (void)metricsTrackingWithActionString:(NSString *)actionString;
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString;
- (void)geoTrackingWithURLString:(NSString *)fullURL
                          extras:(NSDictionary<NSString *, NSString *> *)extras;

// Win/Loss URL firing methods for all ad types
- (void)fireNurlWithPrice:(double)price nUrl:(nullable NSString *)nUrl;
- (void)fireLurlWithUrl:(nullable NSString *)lUrl reason:(NSInteger)reason;
@end

@interface CLXLiveAdEventReporter : NSObject <CLXAdEventReporting>

- (instancetype)initWithEndpoint:(NSString *)endpoint;

@end

NS_ASSUME_NONNULL_END 

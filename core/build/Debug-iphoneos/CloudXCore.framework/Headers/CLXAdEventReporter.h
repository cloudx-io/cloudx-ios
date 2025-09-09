#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdEventReporting <NSObject>
- (void)impressionWithBidID:(NSString *)bidID;
- (void)winWithBidID:(NSString *)bidID;
- (void)showBannerNUrlActionWithPrice:(double)price nUrl:(nullable NSString *)nUrl;
- (void)metricsTrackingWithActionString:(NSString *)actionString;
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString;
- (void)geoTrackingWithURLString:(NSString *)fullURL
                          extras:(NSDictionary<NSString *, NSString *> *)extras;
@end

@interface CLXLiveAdEventReporter : NSObject <CLXAdEventReporting>

- (instancetype)initWithEndpoint:(NSString *)endpoint;

@end

NS_ASSUME_NONNULL_END 

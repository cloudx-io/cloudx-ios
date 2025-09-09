#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdEventReporting <NSObject>
- (void)impressionWithBidID:(NSString *)bidID;
- (void)winWithBidID:(NSString *)bidID;
- (void)showBannerNUrlActionWithPrice:(double)price nUrl:(nullable NSString *)nUrl;
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString;
- (void)geoTrackingWithURLString:(NSString *)fullURL
                          extras:(NSDictionary<NSString *, NSString *> *)extras;
//                      completion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable, NSError * _Nullable))completion;
@end

@interface CLXLiveAdEventReporter : NSObject <CLXAdEventReporting>

- (instancetype)initWithEndpoint:(NSString *)endpoint;

@end

NS_ASSUME_NONNULL_END 

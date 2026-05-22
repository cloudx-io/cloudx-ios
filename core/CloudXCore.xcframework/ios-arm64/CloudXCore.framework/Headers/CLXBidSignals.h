#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdType.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBidRequestPayload;
@class CLXSessionMetricsTracker;

/** Builds the v2 SDK→server SignalPayload + matching CLXLegacyTrackerSnapshot. Session-scoped. */
@interface CLXBidSignals : NSObject

- (instancetype)initWithSessionMetricsTracker:(CLXSessionMetricsTracker *)sessionMetricsTracker
                           configPayloadToken:(NSString *)configPayloadToken
                                      country:(NSString *)country
                                    deviceIFA:(NSString *)deviceIFA
                                    deviceIFV:(nullable NSString *)deviceIFV;

- (CLXBidRequestPayload *)createBidRequestPayloadWithAdUnitId:(NSString *)adUnitId
                                                       adType:(CLXAdType)adType
                                                       format:(NSString *)format
                                                 bidderTokens:(nullable NSDictionary<NSString *, NSDictionary *> *)bidderTokens
                                          localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                                                    auctionId:(NSString *)auctionId;

- (CLXBidRequestPayload *)createBidRequestPayloadWithAdUnitId:(NSString *)adUnitId
                                                       adType:(CLXAdType)adType
                                                       format:(NSString *)format
                                                 bidderTokens:(nullable NSDictionary<NSString *, NSDictionary *> *)bidderTokens
                                          localExtraParameters:(nullable NSDictionary<NSString *, id> *)localExtraParameters
                                               arbiterEnabled:(BOOL)arbiterEnabled
                                                   auctionId:(NSString *)auctionId;

@end

NS_ASSUME_NONNULL_END

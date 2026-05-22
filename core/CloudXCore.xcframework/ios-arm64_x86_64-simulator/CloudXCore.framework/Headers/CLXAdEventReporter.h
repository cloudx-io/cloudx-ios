#import <Foundation/Foundation.h>

@class CLXAd;
@protocol CLXAdDelegate;

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdEventReporting <NSObject>
- (void)metricsTrackingWithActionString:(NSString *)actionString;
- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString;

// Replay-on-launch: drain SQLite-cached Rill / metrics events from previous sessions.
// Both dispatch async — must NOT block CloudXCoreAPI init.
- (void)trySendingPendingRillEvents;
- (void)trySendingPendingMetricsEvents;

// Legacy win/loss methods removed - use CLXWinLossTracker for server-side tracking
@end

@interface CLXAdEventReporter : NSObject <CLXAdEventReporting>

- (instancetype)initWithEndpoint:(NSString *)endpoint;

@end

NS_ASSUME_NONNULL_END 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * MetricsTracker is responsible for sending pending metrics to the server.
 * It fetches AppSessionModel from CoreData and sends them via MetricsNetworkService.
 */
@interface CLXMetricsTracker : NSObject

/**
 * Returns the shared singleton instance of MetricsTracker.
 * @return The shared MetricsTracker instance.
 */
+ (instancetype)shared;

/**
 * Attempts to send pending metrics to the server.
 * This method fetches AppSessionModel from CoreData and sends them via MetricsNetworkService.
 * @param completion Completion block called when the operation finishes.
 */
- (void)trySendPendingMetricsWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END 
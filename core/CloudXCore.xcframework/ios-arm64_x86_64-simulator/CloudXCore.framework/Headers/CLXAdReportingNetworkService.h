#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXAdReportingEventStore;
@class CLXBaseNetworkService;

@interface CLXAdReportingNetworkService : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL
                     urlSession:(NSURLSession *)urlSession
                   userDefaults:(NSUserDefaults *)userDefaults;

/**
 * Designated initializer used by tests to inject a custom event store
 * (e.g. one backed by a unique-per-test SQLite file). Production callers
 * should prefer the URL/session/userDefaults init above.
 */
- (instancetype)initWithBaseURL:(NSURL *)baseURL
                     urlSession:(NSURLSession *)urlSession
                   userDefaults:(NSUserDefaults *)userDefaults
                     eventStore:(nullable CLXAdReportingEventStore *)eventStore;

// Legacy trackNUrlWithPrice and trackLUrlWithLUrl methods removed
// Use CLXWinLossNetworkService for server-side win/loss tracking instead
- (void)rillTrackingWithActionString:(NSString *)urlString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString error:(NSError **)error;
- (void)metricsTrackingWithActionString:(NSString *)actionString error:(NSError **)error;

/**
 * Replay all cached Rill rows from previous sessions. Each row is sent via the
 * resilient send path; 2xx/4xx delete the row, 5xx/network/timeout leave it for
 * the next session. Dispatches asynchronously — does NOT block the caller.
 *
 * Note: the legacy metrics POST (metricsTrackingWithActionString:) is
 * deliberately fire-and-forget and is NOT replayed on launch. See PR #710 /
 * PR #709 commit messages for the rationale.
 */
- (void)trySendingPendingRillEvents;

@end

NS_ASSUME_NONNULL_END 

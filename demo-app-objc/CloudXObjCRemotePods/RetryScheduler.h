#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The retry policy of the ad flows after a failed load or show: 2 s, 4 s, 8 s and so on up to 60 s,
 * started over by `reset` after the next successful load. A fixed short delay would turn
 * sustained no-fill into a tight request loop against the ad networks. Main queue only.
 */
@interface RetryScheduler : NSObject

/** YES while a scheduled retry has not run yet. */
@property (nonatomic, readonly, getter=isPending) BOOL pending;

/** Runs `action` after the next backoff delay, replacing a pending retry, and returns the delay in seconds. */
- (NSInteger)scheduleAction:(dispatch_block_t)action;

/** Cancels a pending retry and starts the next failure over at the base delay. */
- (void)reset;

@end

NS_ASSUME_NONNULL_END

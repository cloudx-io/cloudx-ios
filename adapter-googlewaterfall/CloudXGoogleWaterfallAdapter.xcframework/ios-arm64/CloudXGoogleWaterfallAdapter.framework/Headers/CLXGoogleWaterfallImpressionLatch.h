#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static const NSTimeInterval CLXGoogleWaterfallDefaultFallbackGraceSec = 0.25;

@interface CLXGoogleWaterfallImpressionLatch : NSObject

- (instancetype)initWithGraceSec:(NSTimeInterval)graceSec NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (BOOL)win;
- (void)scheduleFallback:(dispatch_block_t)emit;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallBackoffPolicy : NSObject

+ (NSTimeInterval)nextDelayForRetryCount:(NSInteger)retryCount;

+ (NSTimeInterval)throttleDelay;

@end

NS_ASSUME_NONNULL_END

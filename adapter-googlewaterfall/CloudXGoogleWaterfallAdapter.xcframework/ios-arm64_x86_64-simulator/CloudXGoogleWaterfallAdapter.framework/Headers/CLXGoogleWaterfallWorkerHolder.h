#import <Foundation/Foundation.h>

@class CLXGoogleWaterfallPrefetchWorker;

NS_ASSUME_NONNULL_BEGIN

/// Module-global holder so the serve adapter and bid token source can reach the
/// worker the initializer built. Mirrors Android WorkerHolder.
@interface CLXGoogleWaterfallWorkerHolder : NSObject

+ (nullable CLXGoogleWaterfallPrefetchWorker *)current;
+ (void)setCurrent:(nullable CLXGoogleWaterfallPrefetchWorker *)worker;

@end

NS_ASSUME_NONNULL_END

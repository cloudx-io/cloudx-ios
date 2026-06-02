#import <Foundation/Foundation.h>

@class CLXGoogleWaterfallPrefetchWorker;

NS_ASSUME_NONNULL_BEGIN

@interface CLXGoogleWaterfallWorkerHolder : NSObject

+ (nullable CLXGoogleWaterfallPrefetchWorker *)current;
+ (void)setCurrent:(nullable CLXGoogleWaterfallPrefetchWorker *)worker;

@end

NS_ASSUME_NONNULL_END

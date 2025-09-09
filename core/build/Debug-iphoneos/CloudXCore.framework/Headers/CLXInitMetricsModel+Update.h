#import <CloudXCore/CLXInitMetricsModel.h>

@class CLXInitMetrics;

NS_ASSUME_NONNULL_BEGIN

@interface CLXInitMetricsModel (Update)

- (void)updateWithMetrics:(CLXInitMetrics *)metrics;

@end

NS_ASSUME_NONNULL_END 
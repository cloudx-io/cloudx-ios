#import <CloudXCore/CLXPerformanceMetricModel.h>

@class CLXSessionMetricPerformance;

NS_ASSUME_NONNULL_BEGIN

@interface CLXPerformanceMetricModel (Update)

- (void)updateWithMetric:(CLXSessionMetricPerformance *)metric;

@end

NS_ASSUME_NONNULL_END 
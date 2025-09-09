#import <CloudXCore/CLXSessionMetricModel.h>

@class CLXSessionMetricSpend;

NS_ASSUME_NONNULL_BEGIN

@interface CLXSessionMetricModel (Update)

- (void)updateWithMetric:(CLXSessionMetricSpend *)metric;

@end

NS_ASSUME_NONNULL_END 
#import <CloudXCore/CLXAppSessionModel+Update.h>
#import <CloudXCore/CLXSessionMetricModel+Update.h>

@implementation CLXAppSessionModel (Update)

- (void)updateWithSession:(CLXAppSession *)session {
    if (self.metrics.count != session.metrics.count) {
        NSMutableSet<CLXSessionMetricModel *> *metricModels = [NSMutableSet set];
        for (id<CLXSessionMetric> metric in session.metrics) {
            if ([metric isKindOfClass:[CLXSessionMetricSpend class]]) {
                CLXSessionMetricSpend *spendMetric = (CLXSessionMetricSpend *)metric;
                CLXSessionMetricModel *metricModel = [[CLXCoreDataManager shared] fetchSessionMetricWithTimestamp:spendMetric.timestamp];
                if (metricModel == nil) {
                    metricModel = [[CLXSessionMetricModel alloc] initWithContext:self.managedObjectContext];
                }
                [metricModel updateWithMetric:spendMetric];
                [metricModels addObject:metricModel];
            }
        }
        self.metrics = metricModels;
    }
    
    self.duration = session.sessionDuration;
}

@end

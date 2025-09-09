#import <CloudXCore/CLXInitMetricsModel+Update.h>
#import <CloudXCore/CLXInitMetrics.h>

@implementation CLXInitMetricsModel (Update)

- (void)updateWithMetrics:(CLXInitMetrics *)metrics {
    self.appKey = metrics.appKey;
    self.startedAt = metrics.startedAt;
    self.endedAt = metrics.endedAt;
    self.success = metrics.success;
    self.sessionId = metrics.sessionId;
}

@end 
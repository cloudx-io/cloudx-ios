#import <CloudXCore/CLXPerformanceMetricModel+Update.h>
#import <CloudXCore/CLXSessionMetricPerformance.h>

@implementation CLXPerformanceMetricModel (Update)

- (void)updateWithMetric:(CLXSessionMetricPerformance *)metric {
    self.placementID = metric.placementID;
    self.adLoadCount = metric.adLoadCount;
    self.adLoadLatency = metric.adLoadLatency;
    self.bidRequestLatency = metric.bidRequestLatency;
    self.bidResponseCount = metric.bidResponseCount;
    self.clickCount = metric.clickCount;
    self.closeCount = metric.closeCount;
    self.closeLatency = metric.closeLatency;
    self.failToLoadAdCount = metric.failToLoadAdCount;
    self.impressionCount = metric.impressionCount;
}

@end 
#import <CloudXCore/CLXSessionMetricModel+Update.h>
#import <CloudXCore/CLXSessionMetricModel.h>
#import <CloudXCore/CLXSessionMetricSpend.h>

@implementation CLXSessionMetricModel (Update)

- (void)updateWithMetric:(id<CLXSessionMetric>)metric {
    self.placementID = metric.placementID;
    if ([metric isKindOfClass:[CLXSessionMetricSpend class]]) {
        CLXSessionMetricSpend *spend = (CLXSessionMetricSpend *)metric;
        self.type = CLXSessionMetricTypeRawValue(spend.type);
        self.value = spend.value;
    }
    self.timestamp = [NSDate date];
}

@end 
//
//  SessionMetricSpend.m
//  CloudXCore
//
//  Created by Bryan Boyko on 5/22/25.
//

#import <CloudXCore/CLXSessionMetricSpend.h>
#import <CloudXCore/CLXSessionMetric.h>
#import <CloudXCore/CLXSessionMetricType.h>

@implementation CLXSessionMetricSpend

- (instancetype)initWithPlacementID:(NSString *)placementID
                                                               type:(CLXSessionMetricType)type
                               value:(double)value
                            timestamp:(NSDate *)timestamp {
    self = [super init];
    if (self) {
        _placementID = [placementID copy];
        _type = type;
        _value = value;
        _timestamp = [timestamp copy];
    }
    return self;
}


- (NSString *)typeString {
    switch (self.type) {
        case CLXSessionMetricTypeSpend:
            return @"spend";
        case CLXSessionMetricTypeImpression:
            return @"impression";
        case CLXSessionMetricTypeFillRate:
            return @"fill_rate";
        case CLXSessionMetricTypeBidRequestLatency:
            return @"bid_request_success_avg_latency";
        case CLXSessionMetricTypeAdLoadLatency:
            return @"ad_load_success_avg_latency";
        case CLXSessionMetricTypeAdLoadFailCount:
            return @"ad_load_fail_count";
        case CLXSessionMetricTypeCloseLatency:
            return @"ad_avg_time_to_close";
        case CLXSessionMetricTypeCTR:
            return @"ctr";
        case CLXSessionMetricTypeClickCount:
            return @"click_count";
        default:
            return @"spend";
    }
}

@end 
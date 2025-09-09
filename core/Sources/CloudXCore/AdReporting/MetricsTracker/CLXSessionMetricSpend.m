//
//  SessionMetricSpend.m
//  CloudXCore
//
//  Created by Bryan Boyko on 5/22/25.
//

#import <CloudXCore/CLXSessionMetricSpend.h>
#import <CloudXCore/CLXSessionMetric.h>
#import <CloudXCore/CLXSessionMetricType.h>
#import <CloudXCore/CLXSessionMetricModel.h>

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

- (instancetype)initWithMetricModel:(CLXSessionMetricModel *)model {
    self = [super init];
    if (self) {
        _placementID = [model.placementID copy];
        _timestamp = [model.timestamp copy];
        _value = model.value;
        
        // Convert string type to enum
        if ([model.type isEqualToString:@"spend"]) {
            _type = CLXSessionMetricTypeSpend;
        } else if ([model.type isEqualToString:@"impression"]) {
            _type = CLXSessionMetricTypeImpression;
        } else if ([model.type isEqualToString:@"fill_rate"]) {
            _type = CLXSessionMetricTypeFillRate;
        } else if ([model.type isEqualToString:@"bid_request_success_avg_latency"]) {
            _type = CLXSessionMetricTypeBidRequestLatency;
        } else if ([model.type isEqualToString:@"ad_load_success_avg_latency"]) {
            _type = CLXSessionMetricTypeAdLoadLatency;
        } else if ([model.type isEqualToString:@"ad_load_fail_count"]) {
            _type = CLXSessionMetricTypeAdLoadFailCount;
        } else if ([model.type isEqualToString:@"ad_avg_time_to_close"]) {
            _type = CLXSessionMetricTypeCloseLatency;
        } else if ([model.type isEqualToString:@"ctr"]) {
            _type = CLXSessionMetricTypeCTR;
        } else if ([model.type isEqualToString:@"click_count"]) {
            _type = CLXSessionMetricTypeClickCount;
        } else {
            _type = CLXSessionMetricTypeSpend; // Default fallback
        }
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
//
//  SessionMetricType.m
//  CloudXCore
//
//  Created by Migration Tool.
//

#import <CloudXCore/CLXSessionMetricType.h>
#import <CloudXCore/CLXSessionMetricModel.h>

NSString *CLXSessionMetricTypeRawValue(CLXSessionMetricType type) {
    switch (type) {
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
    }
} 
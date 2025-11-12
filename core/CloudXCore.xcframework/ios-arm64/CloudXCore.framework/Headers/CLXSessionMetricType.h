//
//  SessionMetricType.h
//  CloudXCore
//
//  Created by Migration Tool.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXSessionMetricType) {
    CLXSessionMetricTypeSpend,
    CLXSessionMetricTypeImpression,
    CLXSessionMetricTypeFillRate,
    CLXSessionMetricTypeBidRequestLatency,
    CLXSessionMetricTypeAdLoadLatency,
    CLXSessionMetricTypeAdLoadFailCount,
    CLXSessionMetricTypeCloseLatency,
    CLXSessionMetricTypeCTR,
    CLXSessionMetricTypeClickCount
};

NSString *CLXSessionMetricTypeRawValue(CLXSessionMetricType type);

NS_ASSUME_NONNULL_END 
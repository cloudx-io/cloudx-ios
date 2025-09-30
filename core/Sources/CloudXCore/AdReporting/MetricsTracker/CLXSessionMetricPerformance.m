//
//  SessionMetricPerformance.m
//  CloudXCore
//
//  Created by Bryan Boyko on 5/22/25.
//

#import <CloudXCore/CLXSessionMetricPerformance.h>
#import <CloudXCore/CLXSessionMetric.h>
#import <CloudXCore/CLXPerformanceMetric.h>

@implementation CLXSessionMetricPerformance

- (instancetype)initWithPlacementID:(NSString *)placementID
                        adLoadCount:(NSInteger)adLoadCount
                     adLoadLatency:(double)adLoadLatency
                 bidRequestLatency:(double)bidRequestLatency
                  bidResponseCount:(NSInteger)bidResponseCount
                        clickCount:(NSInteger)clickCount
                        closeCount:(NSInteger)closeCount
                     closeLatency:(double)closeLatency
                failToLoadAdCount:(NSInteger)failToLoadAdCount
                   impressionCount:(NSInteger)impressionCount {
    self = [super init];
    if (self) {
        _placementID = [placementID copy];
        _adLoadCount = adLoadCount;
        _adLoadLatency = adLoadLatency;
        _bidRequestLatency = bidRequestLatency;
        _bidResponseCount = bidResponseCount;
        _clickCount = clickCount;
        _closeCount = closeCount;
        _closeLatency = closeLatency;
        _failToLoadAdCount = failToLoadAdCount;
        _impressionCount = impressionCount;
    }
    return self;
}

- (instancetype)initWithPerformanceMetric:(CLXPerformanceMetric *)metric {
    self = [super init];
    if (self) {
        _placementID = [metric.placementId copy];
        _adLoadCount = metric.adLoadCount;
        _adLoadLatency = metric.adLoadLatency;
        _bidRequestLatency = metric.bidRequestLatency;
        _bidResponseCount = metric.bidResponseCount;
        _clickCount = metric.clickCount;
        _closeCount = metric.closeCount;
        _closeLatency = metric.closeLatency;
        _failToLoadAdCount = metric.failToLoadAdCount;
        _impressionCount = metric.impressionCount;
    }
    return self;
}

@end 
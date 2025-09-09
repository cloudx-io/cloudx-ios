//
//  SessionMetricPerformance.m
//  CloudXCore
//
//  Created by Bryan Boyko on 5/22/25.
//

#import <CloudXCore/CLXSessionMetricPerformance.h>
#import <CloudXCore/CLXSessionMetricModel.h>
#import <CloudXCore/CLXSessionMetric.h>
#import <CloudXCore/CLXPerformanceMetricModel.h>

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

- (instancetype)initWithPerformanceMetricModel:(CLXPerformanceMetricModel *)model {
    self = [super init];
    if (self) {
        _placementID = [model.placementID copy];
        _adLoadCount = model.adLoadCount;
        _adLoadLatency = model.adLoadLatency;
        _bidRequestLatency = model.bidRequestLatency;
        _bidResponseCount = model.bidResponseCount;
        _clickCount = model.clickCount;
        _closeCount = model.closeCount;
        _closeLatency = model.closeLatency;
        _failToLoadAdCount = model.failToLoadAdCount;
        _impressionCount = model.impressionCount;
    }
    return self;
}

@end 
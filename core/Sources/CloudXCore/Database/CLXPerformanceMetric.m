/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXPerformanceMetric.h"

@implementation CLXPerformanceMetric

#pragma mark - Initialization

- (instancetype)initWithPlacementId:(NSString *)placementId sessionId:(NSString *)sessionId {
    if (self = [super initWithSessionId:sessionId]) {
        _placementId = [placementId copy];
        _clickCount = 0;
        _impressionCount = 0;
        _closeCount = 0;
        _loadLatency = 0;
        _bidResponseCount = 0;
        _adLoadCount = 0;
        _adLoadLatency = 0.0;
        _bidRequestLatency = 0.0;
        _failToLoadAdCount = 0;
        _closeLatency = 0.0;
    }
    return self;
}

#pragma mark - Metric Operations

- (void)incrementClicks {
    [self incrementClicksBy:1];
}

- (void)incrementClicksBy:(NSInteger)count {
    _clickCount += count;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)incrementImpressions {
    [self incrementImpressionsBy:1];
}

- (void)incrementImpressionsBy:(NSInteger)count {
    _impressionCount += count;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)incrementCloses {
    [self incrementClosesBy:1];
}

- (void)incrementClosesBy:(NSInteger)count {
    _closeCount += count;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)addLoadLatency:(NSInteger)latencyMs {
    _loadLatency += latencyMs;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)incrementBidResponses {
    [self incrementBidResponsesBy:1];
}

- (void)incrementBidResponsesBy:(NSInteger)count {
    _bidResponseCount += count;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)incrementAdLoads {
    [self incrementAdLoadsBy:1];
}

- (void)incrementAdLoadsBy:(NSInteger)count {
    _adLoadCount += count;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)addAdLoadLatency:(double)latency {
    _adLoadLatency += latency;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)addBidRequestLatency:(double)latency {
    _bidRequestLatency += latency;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)incrementFailToLoadAds {
    [self incrementFailToLoadAdsBy:1];
}

- (void)incrementFailToLoadAdsBy:(NSInteger)count {
    _failToLoadAdCount += count;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)addCloseLatency:(double)latency {
    _closeLatency += latency;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

#pragma mark - Analytics

- (NSTimeInterval)averageLoadLatency {
    if (_bidResponseCount == 0) {
        return 0;
    }
    return (NSTimeInterval)_loadLatency / (NSTimeInterval)_bidResponseCount;
}

- (double)clickThroughRate {
    if (_impressionCount == 0) {
        return 0.0;
    }
    return (double)_clickCount / (double)_impressionCount;
}

- (double)closeRate {
    if (_impressionCount == 0) {
        return 0.0;
    }
    return (double)_closeCount / (double)_impressionCount;
}

- (NSDictionary *)performanceSummary {
    return @{
        @"placementId": self.placementId ?: @"",
        @"clickCount": @(self.clickCount),
        @"impressionCount": @(self.impressionCount),
        @"closeCount": @(self.closeCount),
        @"loadLatency": @(self.loadLatency),
        @"bidResponseCount": @(self.bidResponseCount),
        @"averageLoadLatency": @([self averageLoadLatency]),
        @"clickThroughRate": @([self clickThroughRate]),
        @"closeRate": @([self closeRate])
    };
}

#pragma mark - Factory Methods

+ (instancetype)metricForPlacement:(NSString *)placementId sessionId:(NSString *)sessionId {
    return [[CLXPerformanceMetric alloc] initWithPlacementId:placementId sessionId:sessionId];
}

#pragma mark - Database Support

+ (NSArray<NSString *> *)sqlColumnNames {
    return @[@"id", @"placementId", @"sessionId", @"clickCount", @"impressionCount", @"closeCount", @"loadLatency", @"bidResponseCount", @"adLoadCount", @"adLoadLatency", @"bidRequestLatency", @"failToLoadAdCount", @"closeLatency", @"timestamp", @"created_at", @"updated_at"];
}

+ (NSString *)sqlTableName {
    return @"performance_metrics_table";
}

- (NSArray *)sqlInsertValues {
    return @[
        self.eventId ?: @"",
        self.placementId ?: @"",
        self.sessionId ?: @"",
        @(self.clickCount),
        @(self.impressionCount),
        @(self.closeCount),
        @(self.loadLatency),
        @(self.bidResponseCount),
        @(self.adLoadCount),
        @(self.adLoadLatency),
        @(self.bidRequestLatency),
        @(self.failToLoadAdCount),
        @(self.closeLatency),
        @(self.timestamp),
        @(self.createdAt),
        @(self.updatedAt)
    ];
}

- (void)updateFromSQLRow:(NSDictionary *)row {
    [super updateFromSQLRow:row];
    
    if (row[@"placementId"]) {
        _placementId = [row[@"placementId"] copy];
    }
    if (row[@"clickCount"]) {
        _clickCount = [row[@"clickCount"] integerValue];
    }
    if (row[@"impressionCount"]) {
        _impressionCount = [row[@"impressionCount"] integerValue];
    }
    if (row[@"closeCount"]) {
        _closeCount = [row[@"closeCount"] integerValue];
    }
    if (row[@"loadLatency"]) {
        _loadLatency = [row[@"loadLatency"] integerValue];
    }
    if (row[@"bidResponseCount"]) {
        _bidResponseCount = [row[@"bidResponseCount"] integerValue];
    }
    if (row[@"adLoadCount"]) {
        _adLoadCount = [row[@"adLoadCount"] integerValue];
    }
    if (row[@"adLoadLatency"]) {
        _adLoadLatency = [row[@"adLoadLatency"] doubleValue];
    }
    if (row[@"bidRequestLatency"]) {
        _bidRequestLatency = [row[@"bidRequestLatency"] doubleValue];
    }
    if (row[@"failToLoadAdCount"]) {
        _failToLoadAdCount = [row[@"failToLoadAdCount"] integerValue];
    }
    if (row[@"closeLatency"]) {
        _closeLatency = [row[@"closeLatency"] doubleValue];
    }
}

#pragma mark - Serialization Override

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [[super toDictionary] mutableCopy];
    dict[@"placementId"] = self.placementId ?: @"";
    dict[@"clickCount"] = @(self.clickCount);
    dict[@"impressionCount"] = @(self.impressionCount);
    dict[@"closeCount"] = @(self.closeCount);
    dict[@"loadLatency"] = @(self.loadLatency);
    dict[@"bidResponseCount"] = @(self.bidResponseCount);
    dict[@"adLoadCount"] = @(self.adLoadCount);
    dict[@"adLoadLatency"] = @(self.adLoadLatency);
    dict[@"bidRequestLatency"] = @(self.bidRequestLatency);
    dict[@"failToLoadAdCount"] = @(self.failToLoadAdCount);
    dict[@"closeLatency"] = @(self.closeLatency);
    return [dict copy];
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    NSString *placementId = dictionary[@"placementId"];
    NSString *sessionId = dictionary[@"sessionId"];
    
    if (!placementId || !sessionId) {
        return nil;
    }
    
    CLXPerformanceMetric *metric = [[CLXPerformanceMetric alloc] initWithPlacementId:placementId sessionId:sessionId];
    
    if (dictionary[@"clickCount"]) {
        metric.clickCount = [dictionary[@"clickCount"] integerValue];
    }
    if (dictionary[@"impressionCount"]) {
        metric.impressionCount = [dictionary[@"impressionCount"] integerValue];
    }
    if (dictionary[@"closeCount"]) {
        metric.closeCount = [dictionary[@"closeCount"] integerValue];
    }
    if (dictionary[@"loadLatency"]) {
        metric.loadLatency = [dictionary[@"loadLatency"] integerValue];
    }
    if (dictionary[@"bidResponseCount"]) {
        metric.bidResponseCount = [dictionary[@"bidResponseCount"] integerValue];
    }
    if (dictionary[@"adLoadCount"]) {
        metric.adLoadCount = [dictionary[@"adLoadCount"] integerValue];
    }
    if (dictionary[@"adLoadLatency"]) {
        metric.adLoadLatency = [dictionary[@"adLoadLatency"] doubleValue];
    }
    if (dictionary[@"bidRequestLatency"]) {
        metric.bidRequestLatency = [dictionary[@"bidRequestLatency"] doubleValue];
    }
    if (dictionary[@"failToLoadAdCount"]) {
        metric.failToLoadAdCount = [dictionary[@"failToLoadAdCount"] integerValue];
    }
    if (dictionary[@"closeLatency"]) {
        metric.closeLatency = [dictionary[@"closeLatency"] doubleValue];
    }
    if (dictionary[@"timestamp"]) {
        metric.timestamp = [dictionary[@"timestamp"] doubleValue];
    }
    if (dictionary[@"createdAt"]) {
        metric.createdAt = [dictionary[@"createdAt"] doubleValue];
    }
    if (dictionary[@"updatedAt"]) {
        metric.updatedAt = [dictionary[@"updatedAt"] doubleValue];
    }
    
    return metric;
}

#pragma mark - Validation Override

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [[super validationErrors] mutableCopy];
    
    if (!self.placementId || self.placementId.length == 0) {
        [errors addObject:@"Placement ID is required"];
    }
    
    if (self.clickCount < 0) {
        [errors addObject:@"Click count cannot be negative"];
    }
    
    if (self.impressionCount < 0) {
        [errors addObject:@"Impression count cannot be negative"];
    }
    
    if (self.closeCount < 0) {
        [errors addObject:@"Close count cannot be negative"];
    }
    
    if (self.loadLatency < 0) {
        [errors addObject:@"Load latency cannot be negative"];
    }
    
    if (self.bidResponseCount < 0) {
        [errors addObject:@"Bid response count cannot be negative"];
    }
    
    return [errors copy];
}

#pragma mark - NSSecureCoding Override

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.placementId forKey:@"placementId"];
    [coder encodeInteger:self.clickCount forKey:@"clickCount"];
    [coder encodeInteger:self.impressionCount forKey:@"impressionCount"];
    [coder encodeInteger:self.closeCount forKey:@"closeCount"];
    [coder encodeInteger:self.loadLatency forKey:@"loadLatency"];
    [coder encodeInteger:self.bidResponseCount forKey:@"bidResponseCount"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _placementId = [coder decodeObjectOfClass:[NSString class] forKey:@"placementId"];
        _clickCount = [coder decodeIntegerForKey:@"clickCount"];
        _impressionCount = [coder decodeIntegerForKey:@"impressionCount"];
        _closeCount = [coder decodeIntegerForKey:@"closeCount"];
        _loadLatency = [coder decodeIntegerForKey:@"loadLatency"];
        _bidResponseCount = [coder decodeIntegerForKey:@"bidResponseCount"];
    }
    return self;
}

#pragma mark - NSObject Override

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> placementId=%@ impressions=%ld clicks=%ld CTR=%.2f%%",
            NSStringFromClass([self class]), self, self.placementId, 
            (long)self.impressionCount, (long)self.clickCount, [self clickThroughRate] * 100];
}


@end

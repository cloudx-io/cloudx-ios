/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsEvent.h"

@implementation CLXMetricsEvent

#pragma mark - Initialization

- (instancetype)initWithEventId:(NSString *)eventId
                      sessionId:(NSString *)sessionId
                     metricName:(NSString *)metricName
                      auctionId:(NSString *)auctionId {
    if (self = [super initWithEventId:eventId sessionId:sessionId]) {
        _metricName = [metricName copy];
        _auctionId = [auctionId copy];
        _counter = 0;
        _totalLatency = 0;
    }
    return self;
}

- (instancetype)initWithSessionId:(NSString *)sessionId
                       metricName:(NSString *)metricName
                        auctionId:(NSString *)auctionId {
    if (self = [super initWithSessionId:sessionId]) {
        _metricName = [metricName copy];
        _auctionId = [auctionId copy];
        _counter = 0;
        _totalLatency = 0;
    }
    return self;
}

#pragma mark - Metrics Operations

- (void)incrementCounter {
    [self incrementCounterBy:1];
}

- (void)incrementCounterBy:(NSInteger)amount {
    _counter += amount;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (void)addLatency:(NSInteger)latencyMs {
    _totalLatency += latencyMs;
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (NSTimeInterval)averageLatency {
    if (_counter == 0) {
        return 0;
    }
    return (NSTimeInterval)_totalLatency / (NSTimeInterval)_counter;
}

#pragma mark - Factory Methods

+ (instancetype)impressionMetricWithSessionId:(NSString *)sessionId auctionId:(NSString *)auctionId {
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithSessionId:sessionId
                                                             metricName:@"impression"
                                                              auctionId:auctionId];
    [event incrementCounter];
    return event;
}

+ (instancetype)clickMetricWithSessionId:(NSString *)sessionId auctionId:(NSString *)auctionId {
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithSessionId:sessionId
                                                             metricName:@"click"
                                                              auctionId:auctionId];
    [event incrementCounter];
    return event;
}

+ (instancetype)loadLatencyMetricWithSessionId:(NSString *)sessionId 
                                     auctionId:(NSString *)auctionId 
                                       latency:(NSInteger)latencyMs {
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithSessionId:sessionId
                                                             metricName:@"load_latency"
                                                              auctionId:auctionId];
    [event addLatency:latencyMs];
    [event incrementCounter];
    return event;
}

#pragma mark - Database Support

+ (NSArray<NSString *> *)sqlColumnNames {
    return @[@"id", @"metricName", @"counter", @"totalLatency", @"sessionId", @"auctionId", @"created_at", @"updated_at"];
}

+ (NSString *)sqlTableName {
    return @"metrics_event_table";
}

- (NSArray *)sqlInsertValues {
    return @[
        self.eventId ?: @"",
        self.metricName ?: @"",
        @(self.counter),
        @(self.totalLatency),
        self.sessionId ?: @"",
        self.auctionId ?: @"",
        @(self.createdAt),
        @(self.updatedAt)
    ];
}

- (void)updateFromSQLRow:(NSDictionary *)row {
    [super updateFromSQLRow:row];
    
    if (row[@"metricName"]) {
        _metricName = [row[@"metricName"] copy];
    }
    if (row[@"counter"]) {
        _counter = [row[@"counter"] integerValue];
    }
    if (row[@"totalLatency"]) {
        _totalLatency = [row[@"totalLatency"] integerValue];
    }
    if (row[@"auctionId"]) {
        _auctionId = [row[@"auctionId"] copy];
    }
}

#pragma mark - Serialization Override

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [[super toDictionary] mutableCopy];
    dict[@"metricName"] = self.metricName ?: @"";
    dict[@"counter"] = @(self.counter);
    dict[@"totalLatency"] = @(self.totalLatency);
    dict[@"auctionId"] = self.auctionId ?: @"";
    return [dict copy];
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    if (!dictionary) {
        return nil;
    }
    
    // Extract fields with defaults for missing values
    NSString *eventId = dictionary[@"id"] ?: @"";
    NSString *sessionId = dictionary[@"sessionId"] ?: @"";
    NSString *metricName = dictionary[@"metricName"] ?: @"";
    NSString *auctionId = dictionary[@"auctionId"] ?: @"";
    
    CLXMetricsEvent *event = [[CLXMetricsEvent alloc] initWithEventId:eventId
                                                            sessionId:sessionId
                                                           metricName:metricName
                                                            auctionId:auctionId];
    
    if (dictionary[@"counter"]) {
        event.counter = [dictionary[@"counter"] integerValue];
    }
    if (dictionary[@"totalLatency"]) {
        event.totalLatency = [dictionary[@"totalLatency"] integerValue];
    }
    if (dictionary[@"timestamp"]) {
        event.timestamp = [dictionary[@"timestamp"] doubleValue];
    }
    if (dictionary[@"created_at"]) {
        event.createdAt = [dictionary[@"created_at"] doubleValue];
    }
    if (dictionary[@"updated_at"]) {
        event.updatedAt = [dictionary[@"updated_at"] doubleValue];
    }
    if (dictionary[@"status"]) {
        event.status = [dictionary[@"status"] integerValue];
    }
    if (dictionary[@"retryCount"]) {
        event.retryCount = [dictionary[@"retryCount"] integerValue];
    }
    if (dictionary[@"lastRetryAt"]) {
        event.lastRetryAt = [dictionary[@"lastRetryAt"] doubleValue];
    }
    
    return event;
}

#pragma mark - Validation Override

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [[super validationErrors] mutableCopy];
    
    if (!self.metricName || self.metricName.length == 0) {
        [errors addObject:@"Metric name is required"];
    }
    
    if (!self.auctionId || self.auctionId.length == 0) {
        [errors addObject:@"Auction ID is required"];
    }
    
    if (self.counter < 0) {
        [errors addObject:@"Counter cannot be negative"];
    }
    
    if (self.totalLatency < 0) {
        [errors addObject:@"Total latency cannot be negative"];
    }
    
    return [errors copy];
}

#pragma mark - NSSecureCoding Override

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.metricName forKey:@"metricName"];
    [coder encodeInteger:self.counter forKey:@"counter"];
    [coder encodeInteger:self.totalLatency forKey:@"totalLatency"];
    [coder encodeObject:self.auctionId forKey:@"auctionId"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _metricName = [coder decodeObjectOfClass:[NSString class] forKey:@"metricName"];
        _counter = [coder decodeIntegerForKey:@"counter"];
        _totalLatency = [coder decodeIntegerForKey:@"totalLatency"];
        _auctionId = [coder decodeObjectOfClass:[NSString class] forKey:@"auctionId"];
    }
    return self;
}

#pragma mark - NSObject Override

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> eventId=%@ sessionId=%@ metricName=%@ counter=%ld totalLatency=%ld auctionId=%@",
            NSStringFromClass([self class]), self, self.eventId, self.sessionId, self.metricName, 
            (long)self.counter, (long)self.totalLatency, self.auctionId];
}


@end

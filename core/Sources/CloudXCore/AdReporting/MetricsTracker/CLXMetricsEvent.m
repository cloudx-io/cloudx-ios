/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMetricsEvent.h"

@implementation CLXMetricsEvent

- (instancetype)initWithEventId:(NSString *)eventId
                     metricName:(NSString *)metricName
                        counter:(NSInteger)counter
                   totalLatency:(NSInteger)totalLatency
                      sessionId:(NSString *)sessionId
                      auctionId:(NSString *)auctionId {
    self = [super init];
    if (self) {
        _eventId = [eventId copy];
        _metricName = [metricName copy];
        _counter = counter;
        _totalLatency = totalLatency;
        _sessionId = [sessionId copy];
        _auctionId = [auctionId copy];
    }
    return self;
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    return [[CLXMetricsEvent alloc] initWithEventId:dictionary[@"id"] ?: @""
                                         metricName:dictionary[@"metricName"] ?: @""
                                            counter:[dictionary[@"counter"] integerValue]
                                       totalLatency:[dictionary[@"totalLatency"] integerValue]
                                          sessionId:dictionary[@"sessionId"] ?: @""
                                          auctionId:dictionary[@"auctionId"] ?: @""];
}

- (NSDictionary *)toDictionary {
    return @{
        @"id": self.eventId,
        @"metricName": self.metricName,
        @"counter": @(self.counter),
        @"totalLatency": @(self.totalLatency),
        @"sessionId": self.sessionId,
        @"auctionId": self.auctionId
    };
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CLXMetricsEvent{id=%@, metric=%@, counter=%ld, latency=%ld, session=%@}",
            self.eventId, self.metricName, (long)self.counter, (long)self.totalLatency, self.sessionId];
}

@end

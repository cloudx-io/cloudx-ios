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

#pragma mark - Serialization

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
    return event;
}

#pragma mark - NSObject Override

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> eventId=%@ sessionId=%@ metricName=%@ counter=%ld totalLatency=%ld auctionId=%@",
            NSStringFromClass([self class]), self, self.eventId, self.sessionId, self.metricName, 
            (long)self.counter, (long)self.totalLatency, self.auctionId];
}


@end

/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXRillEvent.h"

@implementation CLXRillEvent

#pragma mark - Initialization

- (instancetype)initWithEventId:(NSString *)eventId
                      sessionId:(NSString *)sessionId
                        encoded:(NSString *)encoded
                     campaignId:(NSString *)campaignId
                     eventValue:(NSString *)eventValue
                      eventName:(NSString *)eventName
                           type:(NSString *)type {
    if (self = [super initWithEventId:eventId sessionId:sessionId]) {
        _encoded = [encoded copy];
        _campaignId = [campaignId copy];
        _eventValue = [eventValue copy];
        _eventName = [eventName copy];
        _type = [type copy];
    }
    return self;
}

- (instancetype)initWithSessionId:(NSString *)sessionId
                          encoded:(NSString *)encoded
                       campaignId:(NSString *)campaignId
                       eventValue:(NSString *)eventValue
                        eventName:(NSString *)eventName
                             type:(NSString *)type {
    if (self = [super initWithSessionId:sessionId]) {
        _encoded = [encoded copy];
        _campaignId = [campaignId copy];
        _eventValue = [eventValue copy];
        _eventName = [eventName copy];
        _type = [type copy];
    }
    return self;
}

#pragma mark - Factory Methods

+ (instancetype)impressionEventWithSessionId:(NSString *)sessionId
                                  campaignId:(NSString *)campaignId
                                     payload:(NSString *)payload {
    return [[CLXRillEvent alloc] initWithSessionId:sessionId
                                            encoded:payload
                                         campaignId:campaignId
                                         eventValue:@"impression"
                                          eventName:@"impression"
                                               type:@"impression"];
}

+ (instancetype)clickEventWithSessionId:(NSString *)sessionId
                             campaignId:(NSString *)campaignId
                                payload:(NSString *)payload {
    return [[CLXRillEvent alloc] initWithSessionId:sessionId
                                            encoded:payload
                                         campaignId:campaignId
                                         eventValue:@"click"
                                          eventName:@"click"
                                               type:@"click"];
}

+ (instancetype)conversionEventWithSessionId:(NSString *)sessionId
                                  campaignId:(NSString *)campaignId
                                     payload:(NSString *)payload {
    return [[CLXRillEvent alloc] initWithSessionId:sessionId
                                            encoded:payload
                                         campaignId:campaignId
                                         eventValue:@"conversion"
                                          eventName:@"conversion"
                                               type:@"conversion"];
}

#pragma mark - Payload Management

- (void)updateEncodedPayload:(NSString *)payload {
    _encoded = [payload copy];
    self.updatedAt = [[NSDate date] timeIntervalSince1970];
}

- (BOOL)hasValidPayload {
    return self.encoded && self.encoded.length > 0;
}

#pragma mark - Database Support

+ (NSString *)sqlTableName {
    return @"cached_tracking_events_table";
}

+ (NSArray<NSString *> *)sqlColumnNames {
    return @[@"id", @"encoded", @"campaignId", @"eventValue", @"eventName", @"type", @"created_at", @"updated_at", @"retry_count", @"last_retry_at", @"status"];
}

- (NSArray *)sqlInsertValues {
    return @[
        self.eventId ?: @"",
        self.encoded ?: @"",
        self.campaignId ?: @"",
        self.eventValue ?: @"",
        self.eventName ?: @"",
        self.type ?: @"",
        @(self.createdAt),
        @(self.updatedAt),
        @(self.retryCount),
        @(self.lastRetryAt),
        @(self.status)  // Use integer status, not string
    ];
}

- (void)updateFromSQLRow:(NSDictionary *)row {
    [super updateFromSQLRow:row];
    
    if (row[@"encoded"]) {
        _encoded = [row[@"encoded"] copy];
    }
    if (row[@"campaignId"]) {
        _campaignId = [row[@"campaignId"] copy];
    }
    if (row[@"eventValue"]) {
        _eventValue = [row[@"eventValue"] copy];
    }
    if (row[@"eventName"]) {
        _eventName = [row[@"eventName"] copy];
    }
    if (row[@"type"]) {
        _type = [row[@"type"] copy];
    }
}

#pragma mark - Serialization Override

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [[super toDictionary] mutableCopy];
    dict[@"encoded"] = self.encoded ?: @"";
    dict[@"campaignId"] = self.campaignId ?: @"";
    dict[@"eventValue"] = self.eventValue ?: @"";
    dict[@"eventName"] = self.eventName ?: @"";
    dict[@"type"] = self.type ?: @"";
    return [dict copy];
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    NSString *eventId = dictionary[@"eventId"];
    NSString *sessionId = dictionary[@"sessionId"];
    NSString *encoded = dictionary[@"encoded"];
    NSString *campaignId = dictionary[@"campaignId"];
    NSString *eventValue = dictionary[@"eventValue"];
    NSString *eventName = dictionary[@"eventName"];
    NSString *type = dictionary[@"type"];
    
    if (!eventId || !sessionId || !campaignId || !eventName || !type) {
        return nil;
    }
    
    CLXRillEvent *event = [[CLXRillEvent alloc] initWithEventId:eventId
                                                      sessionId:sessionId
                                                        encoded:encoded ?: @""
                                                     campaignId:campaignId
                                                     eventValue:eventValue ?: @""
                                                      eventName:eventName
                                                           type:type];
    
    if (dictionary[@"timestamp"]) {
        event.timestamp = [dictionary[@"timestamp"] doubleValue];
    }
    if (dictionary[@"createdAt"]) {
        event.createdAt = [dictionary[@"createdAt"] doubleValue];
    }
    if (dictionary[@"updatedAt"]) {
        event.updatedAt = [dictionary[@"updatedAt"] doubleValue];
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
    
    if (!self.campaignId || self.campaignId.length == 0) {
        [errors addObject:@"Campaign ID is required"];
    }
    
    if (!self.eventName || self.eventName.length == 0) {
        [errors addObject:@"Event name is required"];
    }
    
    if (!self.type || self.type.length == 0) {
        [errors addObject:@"Event type is required"];
    }
    
    // Encoded payload is optional but if present should not be empty
    if (self.encoded && self.encoded.length == 0) {
        [errors addObject:@"Encoded payload cannot be empty string"];
    }
    
    return [errors copy];
}

#pragma mark - CLXEventProtocol Optional Methods

- (NSString *)encryptedPayload {
    return self.encoded;
}

- (void)setEncryptedPayload:(NSString *)payload {
    [self updateEncodedPayload:payload];
}

#pragma mark - NSSecureCoding Override

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.encoded forKey:@"encoded"];
    [coder encodeObject:self.campaignId forKey:@"campaignId"];
    [coder encodeObject:self.eventValue forKey:@"eventValue"];
    [coder encodeObject:self.eventName forKey:@"eventName"];
    [coder encodeObject:self.type forKey:@"type"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _encoded = [coder decodeObjectOfClass:[NSString class] forKey:@"encoded"];
        _campaignId = [coder decodeObjectOfClass:[NSString class] forKey:@"campaignId"];
        _eventValue = [coder decodeObjectOfClass:[NSString class] forKey:@"eventValue"];
        _eventName = [coder decodeObjectOfClass:[NSString class] forKey:@"eventName"];
        _type = [coder decodeObjectOfClass:[NSString class] forKey:@"type"];
    }
    return self;
}

#pragma mark - NSObject Override

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> eventId=%@ campaignId=%@ eventName=%@ type=%@ hasPayload=%@",
            NSStringFromClass([self class]), self, self.eventId, self.campaignId, 
            self.eventName, self.type, @([self hasValidPayload])];
}


@end

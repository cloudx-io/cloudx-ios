/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXBaseEvent.h"
#import "CLXError.h"

// Constants
static const NSInteger CLXMaxRetryCount = 3;
static const NSTimeInterval CLXBaseRetryDelay = 1.0; // 1 second

@implementation CLXBaseEvent

@synthesize eventId = _eventId;

#pragma mark - Initialization

- (instancetype)initWithEventId:(NSString *)eventId sessionId:(NSString *)sessionId {
    if (self = [super init]) {
        _eventId = [eventId copy];
        _sessionId = [sessionId copy];
        _timestamp = [[NSDate date] timeIntervalSince1970];
        _createdAt = _timestamp;
        _updatedAt = _timestamp;
        _status = CLXEventStatusPending;
        _retryCount = 0;
        _lastRetryAt = 0;
    }
    return self;
}

- (instancetype)initWithSessionId:(NSString *)sessionId {
    NSString *eventId = [self generateEventId];
    return [self initWithEventId:eventId sessionId:sessionId];
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"CLXBaseEvent is an abstract class. Use initWithEventId:sessionId: or initWithSessionId:"
                                 userInfo:nil];
}

#pragma mark - Private Methods

- (NSString *)generateEventId {
    return [[NSUUID UUID] UUIDString];
}

#pragma mark - CLXEventProtocol

// eventId getter is automatically synthesized

- (NSString *)sessionId {
    return _sessionId;
}

- (NSTimeInterval)timestamp {
    return _timestamp;
}

- (CLXEventStatus)status {
    return _status;
}

- (BOOL)isValid {
    NSArray *errors = [self validationErrors];
    return errors.count == 0;
}

- (NSDictionary *)toDictionary {
    return @{
        @"id": self.eventId ?: @"",
        @"sessionId": self.sessionId ?: @"",
        @"timestamp": @(self.timestamp),
        @"createdAt": @(self.createdAt),
        @"updatedAt": @(self.updatedAt),
        @"status": @(self.status),
        @"retryCount": @(self.retryCount),
        @"lastRetryAt": @(self.lastRetryAt)
    };
}

#pragma mark - Validation

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [NSMutableArray array];
    
    if (!self.eventId || self.eventId.length == 0) {
        [errors addObject:@"Event ID is required"];
    }
    
    if (!self.sessionId || self.sessionId.length == 0) {
        [errors addObject:@"Session ID is required"];
    }
    
    if (self.timestamp <= 0) {
        [errors addObject:@"Timestamp must be positive"];
    }
    
    if (self.createdAt <= 0) {
        [errors addObject:@"Created timestamp must be positive"];
    }
    
    return [errors copy];
}

#pragma mark - Serialization

- (NSString *)toJSONString {
    NSDictionary *dictionary = [self toDictionary];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error) {
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    // This is an abstract method - subclasses must implement
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"fromDictionary: must be implemented by subclasses"
                                 userInfo:nil];
}

+ (instancetype)fromJSONString:(NSString *)jsonString {
    NSError *error;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData
                                                              options:0
                                                                error:&error];
    if (error || !dictionary) {
        return nil;
    }
    
    return [self fromDictionary:dictionary];
}

#pragma mark - Database Support

- (NSArray *)sqlInsertValues {
    // Base implementation - subclasses should override and call super
    return @[
        self.eventId ?: @"",
        self.sessionId ?: @"",
        @(self.timestamp),
        @(self.createdAt),
        @(self.updatedAt),
        @(self.status),
        @(self.retryCount),
        @(self.lastRetryAt)
    ];
}

- (void)updateFromSQLRow:(NSDictionary *)row {
    if (row[@"sessionId"]) {
        _sessionId = [row[@"sessionId"] copy];
    }
    if (row[@"timestamp"]) {
        _timestamp = [row[@"timestamp"] doubleValue];
    }
    if (row[@"createdAt"]) {
        _createdAt = [row[@"createdAt"] doubleValue];
    }
    if (row[@"updatedAt"]) {
        _updatedAt = [row[@"updatedAt"] doubleValue];
    }
    if (row[@"status"]) {
        _status = [row[@"status"] integerValue];
    }
    if (row[@"retryCount"]) {
        _retryCount = [row[@"retryCount"] integerValue];
    }
    if (row[@"lastRetryAt"]) {
        _lastRetryAt = [row[@"lastRetryAt"] doubleValue];
    }
}

#pragma mark - Retry Management

- (void)incrementRetryCount {
    _retryCount++;
    _lastRetryAt = [[NSDate date] timeIntervalSince1970];
    _updatedAt = _lastRetryAt;
}

- (BOOL)canRetry {
    return _retryCount < CLXMaxRetryCount;
}

- (NSTimeInterval)nextRetryDelay {
    // Exponential backoff with jitter
    NSTimeInterval baseDelay = CLXBaseRetryDelay * pow(2, _retryCount);
    NSTimeInterval jitter = (arc4random_uniform(1000) / 1000.0) * baseDelay * 0.1;
    return baseDelay + jitter;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> eventId=%@ sessionId=%@ status=%ld retryCount=%ld",
            NSStringFromClass([self class]), self, self.eventId, self.sessionId, (long)self.status, (long)self.retryCount];
}

- (NSUInteger)hash {
    return [self.eventId hash] ^ [self.sessionId hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[CLXBaseEvent class]]) {
        return NO;
    }
    
    CLXBaseEvent *other = (CLXBaseEvent *)object;
    return [self.eventId isEqualToString:other.eventId] &&
           [self.sessionId isEqualToString:other.sessionId];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    CLXBaseEvent *copy = [[[self class] allocWithZone:zone] initWithEventId:self.eventId sessionId:self.sessionId];
    copy->_timestamp = self.timestamp;
    copy->_createdAt = self.createdAt;
    copy->_updatedAt = self.updatedAt;
    copy->_status = self.status;
    copy->_retryCount = self.retryCount;
    copy->_lastRetryAt = self.lastRetryAt;
    return copy;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.eventId forKey:@"eventId"];
    [coder encodeObject:self.sessionId forKey:@"sessionId"];
    [coder encodeDouble:self.timestamp forKey:@"timestamp"];
    [coder encodeDouble:self.createdAt forKey:@"createdAt"];
    [coder encodeDouble:self.updatedAt forKey:@"updatedAt"];
    [coder encodeInteger:self.status forKey:@"status"];
    [coder encodeInteger:self.retryCount forKey:@"retryCount"];
    [coder encodeDouble:self.lastRetryAt forKey:@"lastRetryAt"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSString *eventId = [coder decodeObjectOfClass:[NSString class] forKey:@"eventId"];
    NSString *sessionId = [coder decodeObjectOfClass:[NSString class] forKey:@"sessionId"];
    
    if (self = [self initWithEventId:eventId sessionId:sessionId]) {
        _timestamp = [coder decodeDoubleForKey:@"timestamp"];
        _createdAt = [coder decodeDoubleForKey:@"createdAt"];
        _updatedAt = [coder decodeDoubleForKey:@"updatedAt"];
        _status = [coder decodeIntegerForKey:@"status"];
        _retryCount = [coder decodeIntegerForKey:@"retryCount"];
        _lastRetryAt = [coder decodeDoubleForKey:@"lastRetryAt"];
    }
    
    return self;
}


@end

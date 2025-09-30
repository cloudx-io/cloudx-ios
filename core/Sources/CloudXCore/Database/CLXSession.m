/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXSession.h"

@implementation CLXSession

#pragma mark - Initialization

- (instancetype)initWithSessionId:(NSString *)sessionId appKey:(NSString *)appKey {
    return [self initWithSessionId:sessionId appKey:appKey url:nil];
}

- (instancetype)initWithSessionId:(NSString *)sessionId appKey:(NSString *)appKey url:(NSString *)url {
    if (self = [super initWithEventId:[[NSUUID UUID] UUIDString] sessionId:sessionId]) {
        _appKey = [appKey copy];
        _url = [url copy];
        _startTime = [[NSDate date] timeIntervalSince1970];
        _endTime = 0;
        _duration = 0;
    }
    return self;
}

#pragma mark - Session Lifecycle

- (void)startSession {
    _startTime = [[NSDate date] timeIntervalSince1970];
    _endTime = 0;
    _duration = 0;
    self.updatedAt = _startTime;
}

- (void)endSession {
    _endTime = [[NSDate date] timeIntervalSince1970];
    [self updateDuration];
    self.updatedAt = _endTime;
}

- (void)updateDuration {
    if (_startTime > 0) {
        NSTimeInterval currentTime = _endTime > 0 ? _endTime : [[NSDate date] timeIntervalSince1970];
        _duration = currentTime - _startTime;
    }
}

- (BOOL)isActive {
    return _startTime > 0 && _endTime == 0;
}

#pragma mark - Factory Methods

+ (instancetype)currentSessionWithAppKey:(NSString *)appKey {
    NSString *sessionId = [NSString stringWithFormat:@"session_%@_%ld", 
                          appKey, (long)[[NSDate date] timeIntervalSince1970]];
    return [[CLXSession alloc] initWithSessionId:sessionId appKey:appKey];
}

+ (instancetype)sessionWithAppKey:(NSString *)appKey url:(NSString *)url {
    NSString *sessionId = [NSString stringWithFormat:@"session_%@_%ld", 
                          appKey, (long)[[NSDate date] timeIntervalSince1970]];
    return [[CLXSession alloc] initWithSessionId:sessionId appKey:appKey url:url];
}

#pragma mark - Database Support

+ (NSArray<NSString *> *)sqlColumnNames {
    return @[@"id", @"sessionId", @"appKey", @"startTime", @"endTime", @"duration", @"url", @"created_at", @"updated_at"];
}

+ (NSString *)sqlTableName {
    return @"session_table";
}

- (NSArray *)sqlInsertValues {
    return @[
        self.eventId ?: @"",
        self.sessionId ?: @"",
        self.appKey ?: @"",
        @(self.startTime),
        @(self.endTime),
        @(self.duration),
        self.url ?: @"",
        @(self.createdAt),
        @(self.updatedAt)
    ];
}

- (void)updateFromSQLRow:(NSDictionary *)row {
    [super updateFromSQLRow:row];
    
    if (row[@"appKey"]) {
        _appKey = [row[@"appKey"] copy];
    }
    if (row[@"startTime"]) {
        _startTime = [row[@"startTime"] doubleValue];
    }
    if (row[@"endTime"]) {
        _endTime = [row[@"endTime"] doubleValue];
    }
    if (row[@"duration"]) {
        _duration = [row[@"duration"] doubleValue];
    }
    if (row[@"url"]) {
        _url = [row[@"url"] copy];
    }
}

#pragma mark - Serialization Override

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [[super toDictionary] mutableCopy];
    dict[@"appKey"] = self.appKey ?: @"";
    dict[@"startTime"] = @(self.startTime);
    dict[@"endTime"] = @(self.endTime);
    dict[@"duration"] = @(self.duration);
    dict[@"url"] = self.url ?: @"";
    return [dict copy];
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    NSString *sessionId = dictionary[@"sessionId"];
    NSString *appKey = dictionary[@"appKey"];
    NSString *url = dictionary[@"url"];
    
    if (!sessionId || !appKey) {
        return nil;
    }
    
    CLXSession *session = [[CLXSession alloc] initWithSessionId:sessionId appKey:appKey url:url];
    
    if (dictionary[@"startTime"]) {
        session.startTime = [dictionary[@"startTime"] doubleValue];
    }
    if (dictionary[@"endTime"]) {
        session.endTime = [dictionary[@"endTime"] doubleValue];
    }
    if (dictionary[@"duration"]) {
        session.duration = [dictionary[@"duration"] doubleValue];
    }
    if (dictionary[@"timestamp"]) {
        session.timestamp = [dictionary[@"timestamp"] doubleValue];
    }
    if (dictionary[@"createdAt"]) {
        session.createdAt = [dictionary[@"createdAt"] doubleValue];
    }
    if (dictionary[@"updatedAt"]) {
        session.updatedAt = [dictionary[@"updatedAt"] doubleValue];
    }
    
    return session;
}

#pragma mark - Validation Override

- (NSArray<NSString *> *)validationErrors {
    NSMutableArray *errors = [[super validationErrors] mutableCopy];
    
    if (!self.appKey || self.appKey.length == 0) {
        [errors addObject:@"App key is required"];
    }
    
    if (self.startTime <= 0) {
        [errors addObject:@"Start time must be positive"];
    }
    
    if (self.endTime > 0 && self.endTime < self.startTime) {
        [errors addObject:@"End time cannot be before start time"];
    }
    
    return [errors copy];
}

#pragma mark - NSSecureCoding Override

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.appKey forKey:@"appKey"];
    [coder encodeDouble:self.startTime forKey:@"startTime"];
    [coder encodeDouble:self.endTime forKey:@"endTime"];
    [coder encodeDouble:self.duration forKey:@"duration"];
    [coder encodeObject:self.url forKey:@"url"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _appKey = [coder decodeObjectOfClass:[NSString class] forKey:@"appKey"];
        _startTime = [coder decodeDoubleForKey:@"startTime"];
        _endTime = [coder decodeDoubleForKey:@"endTime"];
        _duration = [coder decodeDoubleForKey:@"duration"];
        _url = [coder decodeObjectOfClass:[NSString class] forKey:@"url"];
    }
    return self;
}

#pragma mark - NSObject Override

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> sessionId=%@ appKey=%@ duration=%.2f active=%@",
            NSStringFromClass([self class]), self, self.sessionId, self.appKey, 
            self.duration, @([self isActive])];
}


@end

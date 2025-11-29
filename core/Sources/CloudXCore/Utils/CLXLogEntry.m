/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXLogEntry.h>

@interface CLXLogEntry ()
@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, assign, readwrite) CLXLogLevel level;
@property (nonatomic, copy, readwrite) NSString *category;
@property (nonatomic, copy, readwrite) NSString *message;
@end

@implementation CLXLogEntry

- (instancetype)initWithLevel:(CLXLogLevel)level
                     category:(NSString *)category
                      message:(NSString *)message {
    self = [super init];
    if (self) {
        _timestamp = [NSDate date];
        _level = level;
        _category = [category copy];
        _message = [message copy];
    }
    return self;
}

- (NSString *)formattedString {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm:ss.SSS"];
    });
    
    NSString *timestamp = [formatter stringFromDate:self.timestamp];
    NSString *levelName = [self levelNameForLevel:self.level];
    
    return [NSString stringWithFormat:@"[%@] [%@] %@ - %@",
            timestamp, levelName, self.category, self.message];
}

- (NSString *)levelNameForLevel:(CLXLogLevel)level {
    switch (level) {
        case CLXLogLevelVerbose: return @"VERBOSE";
        case CLXLogLevelDebug:   return @"DEBUG";
        case CLXLogLevelInfo:    return @"INFO";
        case CLXLogLevelWarn:    return @"WARN";
        case CLXLogLevelError:   return @"ERROR";
        default:                 return @"UNKNOWN";
    }
}

- (NSString *)description {
    return [self formattedString];
}

@end


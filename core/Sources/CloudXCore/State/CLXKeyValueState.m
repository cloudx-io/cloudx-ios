/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXKeyValueState.h>

@interface CLXKeyValueState ()
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSString *> *userKeyValues;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSString *> *appKeyValues;
@end

@implementation CLXKeyValueState

@synthesize hashedUserId = _hashedUserId;

+ (instancetype)shared {
    static CLXKeyValueState *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userKeyValues = [NSMutableDictionary dictionary];
        _appKeyValues = [NSMutableDictionary dictionary];
        _hashedUserId = nil;
    }
    return self;
}

#pragma mark - Thread-Safe Accessors

- (void)setHashedUserId:(NSString *)hashedUserId {
    @synchronized(self) {
        _hashedUserId = [hashedUserId copy];
    }
}

- (NSString *)hashedUserId {
    @synchronized(self) {
        return _hashedUserId;
    }
}

- (void)setUserKeyValue:(NSString *)key value:(NSString *)value {
    if (key && value) {
        @synchronized(self) {
            self.userKeyValues[key] = value;
        }
    }
}

- (void)setAppKeyValue:(NSString *)key value:(NSString *)value {
    if (key && value) {
        @synchronized(self) {
            self.appKeyValues[key] = value;
        }
    }
}

- (void)clearAllKeyValues {
    @synchronized(self) {
        [self.userKeyValues removeAllObjects];
        [self.appKeyValues removeAllObjects];
        _hashedUserId = nil;
    }
}

@end

/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXKeyValueState.h>

@interface CLXKeyValueState ()
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSString *> *userKeyValues;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSString *> *appKeyValues;
@end

@implementation CLXKeyValueState

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

- (void)setUserKeyValue:(NSString *)key value:(NSString *)value {
    if (key && value) {
        self.userKeyValues[key] = value;
    }
}

- (void)setAppKeyValue:(NSString *)key value:(NSString *)value {
    if (key && value) {
        self.appKeyValues[key] = value;
    }
}

- (void)clearAllKeyValues {
    [self.userKeyValues removeAllObjects];
    [self.appKeyValues removeAllObjects];
    self.hashedUserId = nil;
}

@end

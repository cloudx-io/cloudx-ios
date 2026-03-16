/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXManualPrivacyState.h>

@implementation CLXManualPrivacyState

+ (instancetype)sharedInstance {
    static CLXManualPrivacyState *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)clear {
    self.hasUserConsent = nil;
    self.doNotSell = nil;
}

@end

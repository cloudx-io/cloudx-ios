//
//  CloudXTestVastNetworkInitializer.m
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.03.2024.
//

#import "CLXTestVastNetworkInitializer.h"

@implementation CLXTestVastNetworkInitializer

static BOOL isInitialized = NO;

+ (BOOL)isInitialized {
    return isInitialized;
}

+ (instancetype)createInstance {
    return [[CLXTestVastNetworkInitializer alloc] init];
}

- (BOOL)initializeWithConfig:(CLXBidderConfig *)config {
    // Simple initialization for test adapter
    return YES;
}

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    // Simple initialization for test adapter
    isInitialized = YES;
    if (completion) {
        completion(YES, nil);
    }
}

@end 
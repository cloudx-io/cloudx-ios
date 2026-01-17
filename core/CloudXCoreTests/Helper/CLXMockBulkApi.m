/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXMockBulkApi.h"
#import <CloudXCore/CLXEventAM.h>
#import <CloudXCore/CLXError.h>

@interface CLXMockBulkApi ()
@property (nonatomic, strong) NSMutableArray<CLXEventAM *> *mutableSentEvents;
@property (nonatomic, strong) NSMutableArray<NSString *> *mutableCalledEndpoints;
@property (nonatomic, assign) NSInteger mutableSendCallCount;
@end

@implementation CLXMockBulkApi

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableSentEvents = [NSMutableArray array];
        _mutableCalledEndpoints = [NSMutableArray array];
        _mutableSendCallCount = 0;
        _shouldSucceed = YES;
        _errorToReturn = nil;
    }
    return self;
}

- (NSArray<CLXEventAM *> *)sentEvents {
    return [self.mutableSentEvents copy];
}

- (NSArray<NSString *> *)calledEndpoints {
    return [self.mutableCalledEndpoints copy];
}

- (NSInteger)sendCallCount {
    return self.mutableSendCallCount;
}

- (void)sendToEndpoint:(NSString *)endpointUrl
                 items:(NSArray<CLXEventAM *> *)items
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    self.mutableSendCallCount++;
    
    if (endpointUrl) {
        [self.mutableCalledEndpoints addObject:endpointUrl];
    }
    
    if (items) {
        [self.mutableSentEvents addObjectsFromArray:items];
    }
    
    if (self.shouldSucceed) {
        if (completion) {
            completion(YES, nil);
        }
    } else {
        NSError *error = self.errorToReturn ?: [CLXError errorWithCode:CLXErrorCodeNetworkError
                                                           description:@"Mock network failure"];
        if (completion) {
            completion(NO, error);
        }
    }
    
    // Notify test that send was called - use for XCTestExpectation synchronization
    if (self.onSendCalled) {
        self.onSendCalled();
    }
}

- (void)reset {
    [self.mutableSentEvents removeAllObjects];
    [self.mutableCalledEndpoints removeAllObjects];
    self.mutableSendCallCount = 0;
}

@end

/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXIlrdProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface MockCLXIlrdProvider : NSObject <CLXIlrdProvider>

@property (nonatomic, assign) BOOL shouldSucceedSubscribe;
@property (nonatomic, assign) BOOL shouldSucceedUnsubscribe;
@property (nonatomic, assign) NSInteger subscribeCallCount;
@property (nonatomic, assign) NSInteger unsubscribeCallCount;
@property (nonatomic, copy, nullable) CLXIlrdEventCallback eventCallback;

/**
 * Simulate receiving an event from the platform.
 */
- (void)simulateEvent:(NSDictionary<NSString *, id> *)event;

@end

NS_ASSUME_NONNULL_END

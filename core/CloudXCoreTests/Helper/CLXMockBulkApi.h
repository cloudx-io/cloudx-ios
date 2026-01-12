/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXMockBulkApi.h
 * @brief Mock bulk API for testing metrics sending without real network calls
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXEventTrackerBulkApi.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Mock implementation of CLXEventTrackerBulkApi for testing
 * Captures sent events and allows configuration of success/failure responses
 */
@interface CLXMockBulkApi : NSObject <CLXEventTrackerBulkApi>

/**
 * All events that were sent via sendToEndpoint:items:completion:
 */
@property (nonatomic, readonly) NSArray<CLXEventAM *> *sentEvents;

/**
 * All endpoint URLs that were called
 */
@property (nonatomic, readonly) NSArray<NSString *> *calledEndpoints;

/**
 * Number of times sendToEndpoint:items:completion: was called
 */
@property (nonatomic, readonly) NSInteger sendCallCount;

/**
 * If YES, the mock will return success. If NO, returns failure.
 * Default is YES.
 */
@property (nonatomic, assign) BOOL shouldSucceed;

/**
 * Custom error to return when shouldSucceed is NO.
 * If nil, a generic error is returned.
 */
@property (nonatomic, strong, nullable) NSError *errorToReturn;

/**
 * Clears all captured data (sentEvents, calledEndpoints, sendCallCount)
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END

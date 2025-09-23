/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXEventTrackerBulkApi.h
 * @brief Bulk API client for sending metrics events matching Android exactly
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXEventAM;

/**
 * Bulk API client for sending metrics events
 * Matches Android's EventTrackerBulkApi interface exactly
 */
@protocol CLXEventTrackerBulkApi <NSObject>

/**
 * Send bulk events to the metrics endpoint
 * Matches Android's suspend fun send(endpointUrl: String, items: List<EventAM>): Result<Unit, CloudXError>
 */
- (void)sendToEndpoint:(NSString *)endpointUrl
                 items:(NSArray<CLXEventAM *> *)items
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

/**
 * Implementation of bulk API client
 */
@interface CLXEventTrackerBulkApiImpl : NSObject <CLXEventTrackerBulkApi>

- (instancetype)initWithTimeoutMillis:(NSInteger)timeoutMillis;

@end

NS_ASSUME_NONNULL_END

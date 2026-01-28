/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXPayloadBuilder.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Testing category that exposes PayloadBuilder creation for unit tests.
 * Creates a test PayloadBuilder with predictable test data without requiring
 * actual TrackingFieldResolver setup.
 */
@interface CLXPayloadBuilder (Testing)

/**
 * Create a test PayloadBuilder with the given account ID and base payload.
 * This bypasses the normal TrackingFieldResolver setup for testing.
 *
 * @param accountId The account ID for this test builder
 * @param basePayload The base payload template (should contain {eventId} placeholder)
 */
+ (instancetype)testBuilderWithAccountId:(NSString *)accountId
                             basePayload:(NSString *)basePayload;

@end

NS_ASSUME_NONNULL_END

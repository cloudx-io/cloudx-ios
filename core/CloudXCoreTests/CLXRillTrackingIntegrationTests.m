/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <XCTest/XCTest.h>
#import "CLXRillTrackingServiceV2.h"
#import "CLXCloudXDatabase.h"
#import "CLXRillEventDaoImpl.h"
#import "CLXRillEvent.h"

@interface CLXRillTrackingIntegrationTests : XCTestCase

@property (nonatomic, strong) CLXRillTrackingServiceV2 *trackingService;
@property (nonatomic, strong) CLXCloudXDatabase *database;
@property (nonatomic, strong) NSString *testDatabasePath;

@end

@implementation CLXRillTrackingIntegrationTests

- (void)setUp {
    [super setUp];
    
    // Create unique test database for each test
    NSString *tempDir = NSTemporaryDirectory();
    NSString *uniqueName = [NSString stringWithFormat:@"integration_test_%@_%f.db", 
                           NSStringFromSelector(self.invocation.selector), 
                           [[NSDate date] timeIntervalSince1970]];
    self.testDatabasePath = [tempDir stringByAppendingPathComponent:uniqueName];
    [[NSFileManager defaultManager] removeItemAtPath:self.testDatabasePath error:nil];
    
    self.database = [[CLXCloudXDatabase alloc] initWithDatabaseName:uniqueName];
    XCTAssertTrue([self.database openDatabase], @"Should open database");
    
    self.trackingService = [[CLXRillTrackingServiceV2 alloc] initWithEventDao:self.database.rillEventDao];
    // Don't set endpoints to prevent immediate network transmission in tests
    // self.trackingService.baseEndpoint = @"https://test.cloudx.io/api";
    // self.trackingService.bulkEndpoint = @"https://test.cloudx.io/api/bulk";
}

- (void)tearDown {
    [self.database closeDatabase];
    [[NSFileManager defaultManager] removeItemAtPath:self.testDatabasePath error:nil];
    [super tearDown];
}

#pragma mark - End-to-End Tracking Tests

- (void)testEndToEndRillTracking {
    // Test complete flow: track event -> persist to database -> verify storage
    
    // 0. First test direct DAO insertion to verify database is working
    CLXRillEvent *directEvent = [[CLXRillEvent alloc] initWithSessionId:@"test_session"
                                                                encoded:@"direct_test_payload"
                                                             campaignId:@"direct_campaign"
                                                             eventValue:@"direct_impression"
                                                              eventName:@"direct_impression"
                                                                   type:@"impression"];
    
    BOOL directInsertSuccess = [self.database.rillEventDao insertRillEvent:directEvent];
    XCTAssertTrue(directInsertSuccess, @"Direct DAO insert should succeed");
    
    NSArray *directEvents = [self.database.rillEventDao findPendingRillEvents];
    NSLog(@"🧪 Direct test: Found %lu direct events", (unsigned long)directEvents.count);
    XCTAssertEqual(directEvents.count, 1, @"Should have 1 direct event");
    
    // Clear the direct test event (mark as processed then delete)
    [self.database.rillEventDao updateRillEventStatus:directEvent.eventId status:@"completed"];
    [self.database.rillEventDao deleteProcessedRillEvents];
    
    NSArray *afterCleanup = [self.database.rillEventDao findPendingRillEvents];
    NSLog(@"🧪 After cleanup: Found %lu events", (unsigned long)afterCleanup.count);
    
    // 1. Track impression event
    [self.trackingService sendWithEncoded:@"test_encoded_payload"
                               campaignId:@"campaign_123"
                               eventValue:@"impression"
                                eventType:CLXRillEventTypeImpression];
    
    // 2. Wait for async processing
    [self waitForAsyncOperations];
    
    // 3. Verify event was persisted
    NSLog(@"🔍 Querying for pending events...");
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    NSLog(@"🔍 Found %lu pending events", (unsigned long)pendingEvents.count);
    for (CLXRillEvent *evt in pendingEvents) {
        NSLog(@"🔍 Event: ID=%@, encoded=%@, campaignId=%@, eventValue=%@, eventName=%@", 
              evt.eventId, evt.encoded, evt.campaignId, evt.eventValue, evt.eventName);
    }
    XCTAssertEqual(pendingEvents.count, 1, @"Should have 1 pending event");
    
    CLXRillEvent *event = pendingEvents.firstObject;
    XCTAssertEqualObjects(event.encoded, @"test_encoded_payload", @"Encoded payload should match");
    XCTAssertEqualObjects(event.campaignId, @"campaign_123", @"Campaign ID should match");
    XCTAssertEqualObjects(event.eventValue, @"impression", @"Event value should match");
    XCTAssertEqualObjects(event.eventName, @"impression", @"Event name should match");
}

- (void)testMultipleEventTypes {
    // Test tracking different event types
    
    [self.trackingService sendWithEncoded:@"impression_payload"
                               campaignId:@"campaign_123"
                               eventValue:@"impression"
                                eventType:CLXRillEventTypeImpression];
    
    [self.trackingService sendWithEncoded:@"click_payload"
                               campaignId:@"campaign_123"
                               eventValue:@"click"
                                eventType:CLXRillEventTypeClick];
    
    [self.trackingService sendWithEncoded:@"conversion_payload"
                               campaignId:@"campaign_123"
                               eventValue:@"conversion"
                                eventType:CLXRillEventTypeClick];
    
    [self waitForAsyncOperations];
    
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pendingEvents.count, 3, @"Should have 3 pending events");
    
    // Verify event types
    NSSet *eventNames = [NSSet setWithArray:[pendingEvents valueForKey:@"eventName"]];
    NSSet *expectedNames = [NSSet setWithArray:@[@"impression", @"click", @"conversion"]];
    XCTAssertEqualObjects(eventNames, expectedNames, @"Should have all event types");
}

- (void)testBulkEventProcessing {
    // Test bulk processing of multiple events
    
    // Add multiple events
    for (int i = 0; i < 10; i++) {
        [self.trackingService sendWithEncoded:[NSString stringWithFormat:@"payload_%d", i]
                                   campaignId:[NSString stringWithFormat:@"campaign_%d", i]
                                   eventValue:@"impression"
                                    eventType:CLXRillEventTypeImpression];
    }
    
    [self waitForAsyncOperations];
    
    // Verify all events are pending
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pendingEvents.count, 10, @"Should have 10 pending events");
    
    // Test batch processing
    [self.trackingService processPendingEventsInBatch:5];
    [self waitForAsyncOperations];
    
    // Note: In real implementation, this would attempt network calls
    // For testing, we just verify the batch selection works
    NSArray *batchEvents = [self.database.rillEventDao findRillEventsForBatch:5];
    XCTAssertEqual(batchEvents.count, 5, @"Should select 5 events for batch");
}

- (void)testOfflineEventQueuing {
    // Test that events are queued when offline (no endpoint)
    
    self.trackingService.baseEndpoint = nil; // Simulate offline
    
    [self.trackingService sendWithEncoded:@"offline_payload"
                               campaignId:@"offline_campaign"
                               eventValue:@"impression"
                                eventType:CLXRillEventTypeImpression];
    
    [self waitForAsyncOperations];
    
    // Event should still be persisted for later retry
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pendingEvents.count, 1, @"Should queue event when offline");
    
    CLXRillEvent *event = pendingEvents.firstObject;
    XCTAssertEqualObjects(event.campaignId, @"offline_campaign", @"Should persist offline event");
}

- (void)testPendingEventRetry {
    // Test retry mechanism for pending events
    
    // Add some events
    for (int i = 0; i < 3; i++) {
        [self.trackingService sendWithEncoded:@"retry_payload"
                                   campaignId:@"retry_campaign"
                                   eventValue:@"impression"
                                    eventType:CLXRillEventTypeImpression];
    }
    
    [self waitForAsyncOperations];
    
    // Verify events are pending
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pendingEvents.count, 3, @"Should have 3 pending events");
    
    // Trigger retry
    [self.trackingService trySendingPendingTrackingEvents];
    [self waitForAsyncOperations];
    
    // Note: In real implementation with network, events would be processed
    // Here we just verify the retry mechanism is triggered
    XCTAssertEqual([self.trackingService pendingEventCount], 3, @"Events should still be pending without network");
}

#pragma mark - Performance Tests

- (void)testHighVolumeEventProcessing {
    // Test processing large number of events
    
    NSDate *startTime = [NSDate date];
    
    // Add 100 events
    for (int i = 0; i < 100; i++) {
        [self.trackingService sendWithEncoded:[NSString stringWithFormat:@"perf_payload_%d", i]
                                   campaignId:[NSString stringWithFormat:@"perf_campaign_%d", i % 10]
                                   eventValue:@"impression"
                                    eventType:CLXRillEventTypeImpression];
    }
    
    [self waitForAsyncOperations];
    
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:startTime];
    
    // Verify all events were processed
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pendingEvents.count, 100, @"Should have 100 pending events");
    
    // Performance assertion - should complete within reasonable time
    XCTAssertLessThan(duration, 10.0, @"Should process 100 events within 10 seconds");
}

- (void)testConcurrentEventTracking {
    // Test concurrent event tracking
    
    dispatch_group_t group = dispatch_group_create();
    
    // Track events concurrently from multiple threads
    for (int thread = 0; thread < 5; thread++) {
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for (int i = 0; i < 10; i++) {
                [self.trackingService sendWithEncoded:[NSString stringWithFormat:@"concurrent_%d_%d", thread, i]
                                           campaignId:[NSString stringWithFormat:@"campaign_%d", thread]
                                           eventValue:@"impression"
                                            eventType:CLXRillEventTypeImpression];
            }
        });
    }
    
    // Wait for all concurrent operations
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    [self waitForAsyncOperations];
    
    // Verify all events were tracked
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pendingEvents.count, 50, @"Should have 50 events from concurrent tracking");
}

#pragma mark - Data Integrity Tests

- (void)testEventDataIntegrity {
    // Test that event data is preserved accurately
    
    NSString *complexPayload = @"{\"test\":\"data\",\"nested\":{\"value\":123},\"array\":[1,2,3]}";
    NSString *specialCampaignId = @"campaign_with_special_chars_!@#$%";
    
    [self.trackingService sendWithEncoded:complexPayload
                               campaignId:specialCampaignId
                               eventValue:@"complex_impression"
                                eventType:CLXRillEventTypeImpression];
    
    [self waitForAsyncOperations];
    
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pendingEvents.count, 1, @"Should have 1 event");
    
    CLXRillEvent *event = pendingEvents.firstObject;
    XCTAssertEqualObjects(event.encoded, complexPayload, @"Complex payload should be preserved");
    XCTAssertEqualObjects(event.campaignId, specialCampaignId, @"Special characters should be preserved");
    XCTAssertEqualObjects(event.eventValue, @"complex_impression", @"Event value should be preserved");
}

- (void)testEventValidation {
    // Test that invalid events are handled properly
    
    // Try to track event with nil values
    [self.trackingService sendWithEncoded:nil
                               campaignId:@"test_campaign"
                               eventValue:@"impression"
                                eventType:CLXRillEventTypeImpression];
    
    [self waitForAsyncOperations];
    
    // Should still create event with empty encoded value
    NSArray *pendingEvents = [self.database.rillEventDao findPendingRillEvents];
    XCTAssertEqual(pendingEvents.count, 1, @"Should handle nil encoded value");
    
    CLXRillEvent *event = pendingEvents.firstObject;
    XCTAssertEqualObjects(event.encoded, @"", @"Nil encoded should become empty string");
}

#pragma mark - Helper Methods

- (void)waitForAsyncOperations {
    // Wait for async operations to complete
    XCTestExpectation *expectation = [self expectationWithDescription:@"Async operations"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end

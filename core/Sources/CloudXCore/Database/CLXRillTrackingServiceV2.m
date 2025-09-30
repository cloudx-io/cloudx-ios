/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXRillTrackingServiceV2.h"
#import "CLXRillEvent.h"
#import "CLXDaoProtocols.h"
#import "CLXEventTrackerBulkApi.h"
#import "CLXEventAM.h"
#import "CLXTrackingFieldResolver.h"
#import "CLXXorEncryption.h"
#import "CLXLogger.h"
#import "CLXError.h"
#import "CLXBidAdSource.h"
#import "CLXBidResponse.h"
#import "CLXConfigImpressionModel.h"

@interface CLXRillTrackingServiceV2 ()

@property (nonatomic, strong) id<CLXRillEventDao> eventDao;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) CLXEventTrackerBulkApiImpl *bulkApi;
@property (nonatomic, strong) CLXTrackingFieldResolver *fieldResolver;
@property (nonatomic, strong) dispatch_queue_t processingQueue;

// Tracking data cache
@property (nonatomic, copy) NSString *encodedString;
@property (nonatomic, copy) NSString *campaignId;
@property (nonatomic, strong) NSDictionary *trackingContext;

@end

@implementation CLXRillTrackingServiceV2

#pragma mark - Initialization

- (instancetype)initWithEventDao:(id<CLXRillEventDao>)eventDao {
    if (self = [super init]) {
        _eventDao = eventDao;
        _logger = [[CLXLogger alloc] initWithCategory:@"RillTrackingV2"];
        _bulkApi = [[CLXEventTrackerBulkApiImpl alloc] init];
        _fieldResolver = [[CLXTrackingFieldResolver alloc] init];
        _processingQueue = dispatch_queue_create("com.cloudx.rill.processing", DISPATCH_QUEUE_SERIAL);
        _encodedString = @"";
        _campaignId = @"";
    }
    return self;
}

#pragma mark - Core Tracking Methods (Android Parity)

- (void)sendWithEncoded:(NSString *)encoded
             campaignId:(NSString *)campaignId
             eventValue:(NSString *)eventValue
              eventType:(CLXRillEventType)eventType {
    
    NSLog(@"🚀 sendWithEncoded called: encoded=%@, campaignId=%@, eventValue=%@, eventType=%ld", 
          encoded ?: @"(nil)", campaignId ?: @"(nil)", eventValue ?: @"(nil)", (long)eventType);
    
    // Make synchronous for debugging
    NSLog(@"🔄 Calling trackEventWithEncoded synchronously");
    [self trackEventWithEncoded:encoded
                     campaignId:campaignId
                     eventValue:eventValue
                      eventType:eventType];
    NSLog(@"✅ trackEventWithEncoded completed");
}

- (void)trackEventWithEncoded:(NSString *)encoded
                   campaignId:(NSString *)campaignId
                   eventValue:(NSString *)eventValue
                    eventType:(CLXRillEventType)eventType {
    
    NSLog(@"🎯 trackEventWithEncoded called");
    
    // Step 1: Save to database first (Android parity)
    NSString *eventId = [self saveToDbWithEncoded:encoded
                                       campaignId:campaignId
                                       eventValue:eventValue
                                        eventType:eventType];
    
    NSLog(@"📝 Saved event with ID: %@", eventId ?: @"(nil)");
    [self.logger debug:[NSString stringWithFormat:@"Tracking %@ event with ID: %@", [self eventTypeString:eventType], eventId]];
    
    // Step 2: Attempt immediate network transmission
    NSString *endpointUrl = self.baseEndpoint;
    if (!endpointUrl || endpointUrl.length == 0) {
        [self.logger error:[NSString stringWithFormat:@"No endpoint for %@ event, will be retried later", [self eventTypeString:eventType]]];
        return;
    }
    
    NSString *finalUrl = [endpointUrl stringByAppendingFormat:@"/%@", [self eventTypePathSegment:eventType]];
    
    // Step 3: Send individual event
    [self sendEventToURL:finalUrl
                 encoded:encoded
              campaignId:campaignId
              eventValue:eventValue
               eventType:eventType
                 eventId:eventId];
}

- (void)trySendingPendingTrackingEvents {
    dispatch_async(self.processingQueue, ^{
        NSArray<CLXRillEvent *> *cached = [self.eventDao findPendingRillEvents];
        
        if (cached.count == 0) {
            [self.logger debug:@"No pending tracking events to send"];
            return;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"Found %lu pending events to retry", (unsigned long)cached.count]];
        [self sendBulkEvents:cached];
    });
}

#pragma mark - Enhanced Tracking Methods

- (BOOL)setupTrackingDataFromBidResponse:(CLXBidAdSourceResponse *)bidResponse
                                impModel:(CLXConfigImpressionModel *)impModel
                             placementID:(NSString *)placementID
                               loadCount:(NSInteger)loadCount {
    
    if (!bidResponse || !impModel) {
        [self.logger debug:@"Missing bid response or impression model for Rill tracking"];
        return NO;
    }
    
    // Extract campaign ID and setup field resolver context
    // Extract campaign ID from bid response - use bid.cid (campaign ID)
    self.campaignId = bidResponse.bid.cid ?: @"";
    
    // Build tracking context for field resolution
    NSMutableDictionary *context = [NSMutableDictionary dictionary];
    context[@"placementId"] = placementID ?: @"";
    context[@"campaignId"] = self.campaignId;
    context[@"loadCount"] = @(loadCount);
    context[@"bidResponse"] = bidResponse;
    context[@"impModel"] = impModel;
    
    self.trackingContext = [context copy];
    
    // Generate encoded string using field resolver - use buildPayload method
    // The impression tracker URL contains the template/endpoint information
    NSString *auctionId = impModel.auctionID ?: @"";
    self.encodedString = [self.fieldResolver buildPayload:auctionId] ?: @"";
    
    // Encrypt if needed using the proper encryption method
    if (self.encodedString.length > 0) {
        NSString *accountId = [self.fieldResolver getAccountId];
        if (accountId && accountId.length > 0) {
            NSData *secret = [CLXXorEncryption generateXorSecret:accountId];
            self.encodedString = [CLXXorEncryption encrypt:self.encodedString secret:secret];
        }
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Setup Rill tracking data for placement: %@, campaign: %@", 
                                                   placementID, self.campaignId]];
    
    return YES;
}

- (void)trackImpressionWithPlacementID:(NSString *)placementID {
    if (![self validateTrackingSetup]) return;
    
    [self sendWithEncoded:self.encodedString
               campaignId:self.campaignId
               eventValue:@"impression"
                eventType:CLXRillEventTypeImpression];
}

- (void)trackClickWithPlacementID:(NSString *)placementID {
    if (![self validateTrackingSetup]) return;
    
    [self sendWithEncoded:self.encodedString
               campaignId:self.campaignId
               eventValue:@"click"
                eventType:CLXRillEventTypeClick];
}

- (void)trackConversionWithPlacementID:(NSString *)placementID value:(NSString *)value {
    if (![self validateTrackingSetup]) return;
    
    [self sendWithEncoded:self.encodedString
               campaignId:self.campaignId
               eventValue:value ?: @"conversion"
                eventType:CLXRillEventTypeClick];
}

#pragma mark - Bulk Processing

- (void)processPendingEventsInBatch:(NSInteger)batchSize {
    dispatch_async(self.processingQueue, ^{
        NSArray<CLXRillEvent *> *events = [self.eventDao findRillEventsForBatch:batchSize];
        if (events.count > 0) {
            [self sendBulkEvents:events];
        }
    });
}

- (void)flushAllPendingEvents {
    dispatch_async(self.processingQueue, ^{
        NSArray<CLXRillEvent *> *allPending = [self.eventDao findPendingRillEvents];
        if (allPending.count > 0) {
            [self sendBulkEvents:allPending];
        }
    });
}

- (void)sendBulkEvents:(NSArray<CLXRillEvent *> *)events {
    NSString *endpointUrl = self.bulkEndpoint;
    
    if (!endpointUrl || endpointUrl.length == 0) {
        [self.logger info:[NSString stringWithFormat:@"No bulk endpoint configured, cannot send %lu events", 
                                                             (unsigned long)events.count]];
        return;
    }
    
    // Convert to bulk API format using CLXEventAM objects
    NSMutableArray<CLXEventAM *> *items = [NSMutableArray arrayWithCapacity:events.count];
    for (CLXRillEvent *event in events) {
        CLXEventAM *item = [[CLXEventAM alloc] initWithImpression:event.encoded ?: @""
                                                       campaignId:event.campaignId ?: @""
                                                       eventValue:event.eventValue ?: @""
                                                        eventName:event.eventName ?: @""
                                                             type:event.type ?: @""];
        [items addObject:item];
    }
    
    // Send bulk request using the correct method name
    [self.bulkApi sendToEndpoint:endpointUrl
                           items:items
                      completion:^(BOOL success, NSError *error) {
        if (success) {
            // Mark events as processed
            NSMutableArray *eventIds = [NSMutableArray arrayWithCapacity:events.count];
            for (CLXRillEvent *event in events) {
                [eventIds addObject:event.eventId];
            }
            
            [self.eventDao markRillEventsAsProcessed:eventIds];
            [self.logger debug:[NSString stringWithFormat:@"Successfully sent %lu events in bulk", (unsigned long)events.count]];
        } else {
            [self.logger error:[NSString stringWithFormat:@"Bulk send failed: %@", error.localizedDescription]];
            // Events remain in database for retry
        }
    }];
}

#pragma mark - Configuration

- (void)setEndpoint:(NSString *)endpointUrl {
    _baseEndpoint = [endpointUrl copy];
}

- (void)setBulkEndpoint:(NSString *)bulkEndpointUrl {
    _bulkEndpoint = [bulkEndpointUrl copy];
}

#pragma mark - Diagnostics

- (NSInteger)pendingEventCount {
    return [self.eventDao findPendingRillEvents].count;
}

- (NSArray<CLXRillEvent *> *)pendingEvents {
    return [self.eventDao findPendingRillEvents];
}

- (void)clearFailedEvents {
    NSArray<CLXRillEvent *> *failedEvents = [self.eventDao findRillEventsByStatus:@"failed"];
    for (CLXRillEvent *event in failedEvents) {
        [self.eventDao deleteById:event.eventId];
    }
    [self.logger debug:[NSString stringWithFormat:@"Cleared %lu failed events", (unsigned long)failedEvents.count]];
}

#pragma mark - Private Methods

- (NSString *)saveToDbWithEncoded:(NSString *)encoded
                       campaignId:(NSString *)campaignId
                       eventValue:(NSString *)eventValue
                        eventType:(CLXRillEventType)eventType {
    
    // Use eventValue as eventName if it's more specific than the generic type
    NSString *eventName = eventValue && eventValue.length > 0 ? eventValue : [self eventTypeString:eventType];
    
    NSLog(@"🔄 Creating Rill event: encoded=%@, campaignId=%@, eventValue=%@, eventName=%@", 
          encoded ?: @"(nil)", campaignId ?: @"(nil)", eventValue ?: @"(nil)", eventName ?: @"(nil)");
    
    CLXRillEvent *event = [[CLXRillEvent alloc] initWithSessionId:@"current_session" // TODO: Get from session service
                                                          encoded:encoded
                                                       campaignId:campaignId
                                                       eventValue:eventValue
                                                        eventName:eventName
                                                             type:[self eventTypePathSegment:eventType]];
    
    NSLog(@"🔄 Created event with ID: %@", event.eventId ?: @"(nil)");
    
    BOOL success = [self.eventDao insertRillEvent:event];
    NSLog(@"🔄 Insert result: %@", success ? @"SUCCESS" : @"FAILED");
    
    return event.eventId;
}

- (void)sendEventToURL:(NSString *)url
               encoded:(NSString *)encoded
            campaignId:(NSString *)campaignId
            eventValue:(NSString *)eventValue
             eventType:(CLXRillEventType)eventType
               eventId:(NSString *)eventId {
    
    // TODO: Implement individual event sending
    // For now, just mark as completed since we'll rely on bulk processing
    [self.eventDao updateRillEventStatus:eventId status:@"completed"];
}

- (BOOL)validateTrackingSetup {
    if (self.encodedString.length == 0 || self.campaignId.length == 0) {
        [self.logger info:@"Rill tracking not properly setup. Call setupTrackingDataFromBidResponse first"];
        return NO;
    }
    return YES;
}

- (NSString *)eventTypeString:(CLXRillEventType)eventType {
    switch (eventType) {
        case CLXRillEventTypeSDKInit: return @"sdkinit";
        case CLXRillEventTypeClick: return @"click";
        case CLXRillEventTypeImpression: return @"impression";
        case CLXRillEventTypeBidRequest: return @"bidrequest";
        case CLXRillEventTypeSDKError: return @"error";
        case CLXRillEventTypeSDKMetrics: return @"metrics";
    }
}

- (NSString *)eventTypePathSegment:(CLXRillEventType)eventType {
    switch (eventType) {
        case CLXRillEventTypeSDKInit: return @"sdkinitenc";
        case CLXRillEventTypeClick: return @"clickenc";
        case CLXRillEventTypeImpression: return @"sdkimpenc";
        case CLXRillEventTypeBidRequest: return @"bidreqenc";
        case CLXRillEventTypeSDKError: return @"sdkerrorenc";
        case CLXRillEventTypeSDKMetrics: return @"sdkmetricenc";
    }
}

@end

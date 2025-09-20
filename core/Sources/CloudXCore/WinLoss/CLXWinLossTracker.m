/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossTracker.m
 * @brief Implementation of Win/Loss tracker matching Android WinLossTrackerImpl exactly
 */

#import <CloudXCore/CLXWinLossTracker.h>
#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXWinLossFieldResolver.h>
#import <CloudXCore/CLXWinLossNetworkService.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/URLSession+CLX.h>
#import <CloudXCore/CLXSQLiteDatabase.h>

/**
 * Simple model for cached win/loss events
 */
@interface CLXCachedWinLossEvent : NSObject
@property (nonatomic, copy) NSString *eventId;
@property (nonatomic, copy) NSString *endpointUrl;
@property (nonatomic, copy) NSString *payload;
- (instancetype)initWithEventId:(NSString *)eventId endpointUrl:(NSString *)endpointUrl payload:(NSString *)payload;
@end

@implementation CLXCachedWinLossEvent
- (instancetype)initWithEventId:(NSString *)eventId endpointUrl:(NSString *)endpointUrl payload:(NSString *)payload {
    self = [super init];
    if (self) {
        _eventId = [eventId copy];
        _endpointUrl = [endpointUrl copy];
        _payload = [payload copy];
    }
    return self;
}
@end

@interface CLXWinLossTracker ()
@property (nonatomic, strong) CLXAuctionBidManager *auctionBidManager;
@property (nonatomic, strong) CLXWinLossFieldResolver *winLossFieldResolver;
@property (nonatomic, strong) CLXWinLossNetworkService *networkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) CLXSQLiteDatabase *database;

@property (nonatomic, copy, nullable) NSString *appKey;
@property (nonatomic, copy, nullable) NSString *endpointUrl;
@end

@implementation CLXWinLossTracker

static id<CLXWinLossTracking> _testInstance = nil;

+ (instancetype)shared {
    // Return test instance if set (for testing)
    if (_testInstance) {
        return (CLXWinLossTracker *)_testInstance;
    }
    
    // Default production singleton
    static CLXWinLossTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXWinLossTracker alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Testing Support

+ (void)setSharedInstanceForTesting:(id<CLXWinLossTracking>)testInstance {
    _testInstance = testInstance;
}

+ (void)resetSharedInstance {
    _testInstance = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _auctionBidManager = [[CLXAuctionBidManager alloc] init];
        _winLossFieldResolver = [[CLXWinLossFieldResolver alloc] init];
        _logger = [[CLXLogger alloc] initWithCategory:@"WinLossTracker"];
        _database = [[CLXSQLiteDatabase alloc] initWithDatabaseName:@"cloudx_winloss"];
        
        // Create table synchronously since we fixed the deadlock issues in CLXSQLiteDatabase
        [self createWinLossTableIfNeeded];
        
        // Initialize network service with placeholder URL (will be updated when endpoint is set)
        NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"winloss"];
        _networkService = [[CLXWinLossNetworkService alloc] initWithBaseURL:@"" urlSession:urlSession];
    }
    return self;
}

#pragma mark - CLXWinLossTracking Implementation

- (void)setAppKey:(NSString *)appKey {
    _appKey = [appKey copy];
    [self.logger debug:[NSString stringWithFormat:@"🔧 [WinLossTracker] App key set: %@", appKey ? @"YES" : @"NO"]];
}

- (void)setEndpoint:(nullable NSString *)endpointUrl {
    self.endpointUrl = [endpointUrl copy];
    
    // Recreate network service with new endpoint
    if (endpointUrl) {
        NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"winloss"];
        self.networkService = [[CLXWinLossNetworkService alloc] initWithBaseURL:endpointUrl urlSession:urlSession];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [WinLossTracker] Endpoint set: %@", endpointUrl ?: @"(nil)"]];
}

- (void)setConfig:(CLXSDKConfigResponse *)config {
    [self.winLossFieldResolver setConfig:config];
    [self.logger debug:@"🔧 [WinLossTracker] Config set for field resolver"];
}

- (void)trySendingPendingWinLossEvents {
    NSArray<CLXCachedWinLossEvent *> *cachedEvents = [self getAllCachedEvents];
    
    if (cachedEvents.count == 0) {
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"🔄 [WinLossTracker] Retrying %lu cached events", (unsigned long)cachedEvents.count]];
    [self sendCachedEvents:cachedEvents];
}

- (void)addBid:(NSString *)auctionId bid:(CLXBidResponseBid *)bid {
    [self.auctionBidManager addBid:auctionId bid:bid];
}

- (void)setBidLoadResult:(NSString *)auctionId 
                    bidId:(NSString *)bidId 
                  success:(BOOL)success 
               lossReason:(nullable NSNumber *)lossReason {
    [self.auctionBidManager setBidLoadResult:auctionId bidId:bidId success:success lossReason:lossReason];
}

- (void)setWinner:(NSString *)auctionId winningBidId:(NSString *)winningBidId {
    [self.auctionBidManager setBidWinner:auctionId winningBidId:winningBidId];
}

- (void)sendLoss:(NSString *)auctionId bidId:(NSString *)bidId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CLXBidResponseBid *bid = [self.auctionBidManager getBid:auctionId bidId:bidId];
        NSNumber *lossReason = [self.auctionBidManager getBidLossReason:auctionId bidId:bidId];
        double loadedBidPrice = [self.auctionBidManager getLoadedBidPrice:auctionId];
        
        if (!bid) {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] No bid found for loss notification: %@", bidId]];
            return;
        }
        
        // Ensure we always have a loss reason for loss notifications (matches Android behavior)
        if (!lossReason) {
            lossReason = @(CLXLossReasonTechnicalError); // Default to technical error
        }
        
        // Build payload using field resolver (matches Android's buildWinLossPayload)
        NSDictionary<NSString *, id> *payload = [self.winLossFieldResolver buildWinLossPayloadWithAuctionId:auctionId
                                                                                                         bid:bid
                                                                                                  lossReason:lossReason
                                                                                                       isWin:NO
                                                                                               loadedBidPrice:loadedBidPrice];
        
        if (payload) {
            NSString *reasonStr = (lossReason.integerValue == CLXLossReasonLostToHigherBid) ? @"HigherBid" : @"TechError";
            [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossTracker] LOSS: %@ (%@)", bidId, reasonStr]];
            [self trackWinLoss:payload];
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] LOSS payload failed: %@", bidId]];
        }
    });
}

- (void)sendWin:(NSString *)auctionId bidId:(NSString *)bidId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CLXBidResponseBid *bid = [self.auctionBidManager getBid:auctionId bidId:bidId];
        
        if (!bid) {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] No bid found for win notification: %@", bidId]];
            return;
        }
        
        double winnerBidPrice = bid.price;
        
        // Build payload using field resolver (matches Android's buildWinLossPayload)
        NSDictionary<NSString *, id> *payload = [self.winLossFieldResolver buildWinLossPayloadWithAuctionId:auctionId
                                                                                                         bid:bid
                                                                                                  lossReason:nil
                                                                                                       isWin:YES
                                                                                               loadedBidPrice:winnerBidPrice];
        
        if (payload) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossTracker] WIN: %@ ($%.2f)", bidId, winnerBidPrice]];
            [self trackWinLoss:payload];
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] WIN payload failed: %@", bidId]];
        }
        
        // Clear auction data after successful win notification (matches Android)
        [self.auctionBidManager clearAuction:auctionId];
    });
}

- (void)sendLossNotificationsForLosingBids:(NSString *)auctionId
                             winningBidId:(NSString *)winningBidId
                                  allBids:(NSArray<CLXBidResponseBid *> *)allBids {
    
    if (!auctionId || !winningBidId || !allBids || allBids.count == 0) {
        return;
    }
    
    // Set winner in win/loss tracker
    [self setWinner:auctionId winningBidId:winningBidId];
    
    NSInteger lossCount = 0;
    for (CLXBidResponseBid *bid in allBids) {
        // Skip the winner
        if ([bid.id isEqualToString:winningBidId]) {
            continue;
        }
        
        // Send server-side loss notification for losing bid (replaces client-side LURL firing)
        if (bid.id) {
            [self setBidLoadResult:auctionId 
                             bidId:bid.id 
                           success:NO 
                        lossReason:@(CLXLossReasonLostToHigherBid)];
            [self sendLoss:auctionId bidId:bid.id];
            lossCount++;
        }
    }
    
    if (lossCount > 0) {
        [self.logger debug:[NSString stringWithFormat:@"📤 [WinLossTracker] Sent %ld server-side loss notifications", (long)lossCount]];
    }
}

- (void)clearAuction:(NSString *)auctionId {
    [self.auctionBidManager clearAuction:auctionId];
}

#pragma mark - Database Management

- (void)createWinLossTableIfNeeded {
    if (![self.database tableExists:@"cached_win_loss_events_table"]) {
        NSString *createTableSQL = @"CREATE TABLE cached_win_loss_events_table ("
                                   @"id TEXT PRIMARY KEY,"
                                   @"endpointUrl TEXT NOT NULL,"
                                   @"payload TEXT NOT NULL"
                                   @");";
        
        BOOL success = [self.database executeSQL:createTableSQL];
        if (success) {
            [self.logger debug:@"Win/loss events table created successfully"];
        } else {
            [self.logger error:@"Failed to create win/loss events table"];
        }
    }
}

#pragma mark - Private Methods

/**
 * Sends win/loss payload to server with database persistence for retry
 */
- (void)trackWinLoss:(NSDictionary<NSString *, id> *)payload {
    // Save to database first for retry capability
    NSString *eventId = [self saveToDatabase:payload];
    
    NSString *endpoint = self.endpointUrl;
    if (!endpoint || endpoint.length == 0) {
        [self.logger error:@"❌ [WinLossTracker] No endpoint configured for win/loss notification"];
        return;
    }
    
    NSString *appKey = self.appKey;
    if (!appKey || appKey.length == 0) {
        [self.logger error:@"❌ [WinLossTracker] No app key configured for win/loss notification"];
        return;
    }
    
    // Send to server (matches Android's trackerApi.send)
    [self.networkService sendWithAppKey:appKey
                            endpointUrl:endpoint
                                payload:payload
                             completion:^(BOOL success, NSError * _Nullable error) {
        
        if (success) {
            // Remove from database cache on success
            [self deleteEventWithId:eventId];
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] Send failed: %@", 
                               error ? error.localizedDescription : @"Unknown error"]];
            // Keep in database for retry
        }
    }];
}

/**
 * Saves payload to database and returns event ID for tracking
 */
- (NSString *)saveToDatabase:(NSDictionary<NSString *, id> *)payload {
    NSString *eventId = [[NSUUID UUID] UUIDString];
    
    // Convert payload to JSON string
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&error];
    if (error || !jsonData) {
        [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] Failed to serialize payload: %@, payload: %@", error, payload]];
        return eventId;
    }
    
    NSString *payloadJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // Save to database
    [self insertEventWithId:eventId endpointUrl:self.endpointUrl ?: @"" payload:payloadJson];
    
    [self.logger debug:[NSString stringWithFormat:@"💾 [WinLossTracker] Saved event to database with ID: %@", eventId]];
    return eventId;
}

/**
 * Sends cached events from database for retry processing
 */
- (void)sendCachedEvents:(NSArray<CLXCachedWinLossEvent *> *)cachedEvents {
    NSString *endpoint = self.endpointUrl;
    NSString *appKey = self.appKey;
    
    if (!endpoint || endpoint.length == 0) {
        [self.logger error:@"❌ [WinLossTracker] No endpoint configured for cached events"];
        return;
    }
    
    if (!appKey || appKey.length == 0) {
        [self.logger error:@"❌ [WinLossTracker] No app key configured for cached events"];
        return;
    }
    
    // Process each cached event
    for (CLXCachedWinLossEvent *cachedEvent in cachedEvents) {
        NSDictionary *payload = [self parsePayload:cachedEvent.payload];
        if (payload) {
            NSString *eventEndpoint = cachedEvent.endpointUrl.length > 0 ? cachedEvent.endpointUrl : endpoint;
            
            [self.networkService sendWithAppKey:appKey
                                    endpointUrl:eventEndpoint
                                        payload:payload
                                     completion:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    [self.logger debug:[NSString stringWithFormat:@"✅ [WinLossTracker] Cached event sent successfully: %@", cachedEvent.eventId]];
                    [self deleteEventWithId:cachedEvent.eventId];
                } else {
                    [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] Cached event failed: %@", cachedEvent.eventId]];
                }
            }];
        }
    }
}

/**
 * Parses JSON payload string back to dictionary
 */
- (nullable NSDictionary *)parsePayload:(NSString *)payloadJson {
    if (!payloadJson || payloadJson.length == 0) {
        return nil;
    }
    
    NSData *jsonData = [payloadJson dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
        return nil;
    }
    
    NSError *error = nil;
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] Failed to parse cached payload: %@", error]];
        return nil;
    }
    
    return payload;
}

#pragma mark - Database Helper Methods

- (NSArray<CLXCachedWinLossEvent *> *)getAllCachedEvents {
    NSString *selectSQL = @"SELECT id, endpointUrl, payload FROM cached_win_loss_events_table;";
    NSArray<NSDictionary *> *rows = [self.database executeQuery:selectSQL];
    
    NSMutableArray<CLXCachedWinLossEvent *> *events = [NSMutableArray array];
    for (NSDictionary *row in rows) {
        NSString *eventId = row[@"id"] ?: @"";
        NSString *endpointUrl = row[@"endpointUrl"] ?: @"";
        NSString *payload = row[@"payload"] ?: @"";
        
        CLXCachedWinLossEvent *event = [[CLXCachedWinLossEvent alloc] initWithEventId:eventId 
                                                                         endpointUrl:endpointUrl 
                                                                             payload:payload];
        [events addObject:event];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Retrieved %lu cached events", (unsigned long)events.count]];
    return [events copy];
}

- (void)insertEventWithId:(NSString *)eventId endpointUrl:(NSString *)endpointUrl payload:(NSString *)payload {
    if (!eventId) {
        [self.logger error:@"Cannot insert event with nil ID"];
        return;
    }
    
    NSString *insertSQL = @"INSERT OR REPLACE INTO cached_win_loss_events_table (id, endpointUrl, payload) VALUES (?, ?, ?);";
    NSArray *parameters = @[eventId, endpointUrl ?: @"", payload ?: @""];
    
    BOOL success = [self.database executeSQL:insertSQL withParameters:parameters];
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Inserted event with ID: %@", eventId]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to insert event with ID: %@", eventId]];
    }
}

- (void)deleteEventWithId:(NSString *)eventId {
    if (!eventId) {
        [self.logger error:@"Cannot delete event with nil ID"];
        return;
    }
    
    NSString *deleteSQL = @"DELETE FROM cached_win_loss_events_table WHERE id = ?;";
    NSArray *parameters = @[eventId];
    
    BOOL success = [self.database executeSQL:deleteSQL withParameters:parameters];
    if (success) {
        [self.logger debug:[NSString stringWithFormat:@"Deleted event with ID: %@", eventId]];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Failed to delete event with ID: %@", eventId]];
    }
}

- (void)deleteAllEvents {
    NSString *deleteAllSQL = @"DELETE FROM cached_win_loss_events_table;";
    
    BOOL success = [self.database executeSQL:deleteAllSQL];
    if (success) {
        [self.logger debug:@"Deleted all cached events"];
    } else {
        [self.logger error:@"Failed to delete all cached events"];
    }
}


@end

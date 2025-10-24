/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossTracker.m
 * @brief Implementation of Win/Loss tracker
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
#import <CloudXCore/CLXBidLifecycleEvent.h>

/**
 * Model for cached win/loss events with state tracking
 */
@interface CLXCachedWinLossEvent : NSObject
@property (nonatomic, copy) NSString *eventId;
@property (nonatomic, copy) NSString *auctionId;
@property (nonatomic, copy) NSString *bidId;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *endpointUrl;
@property (nonatomic, copy, nullable) NSString *payload;
@property (nonatomic, copy, nullable) NSString *lossPayload;
@property (nonatomic, assign) BOOL sent;
@property (nonatomic, assign) int64_t createdAt;
@property (nonatomic, assign) int64_t updatedAt;
- (instancetype)initWithEventId:(NSString *)eventId 
                     auctionId:(NSString *)auctionId 
                         bidId:(NSString *)bidId 
                         state:(NSString *)state 
                   endpointUrl:(NSString *)endpointUrl 
                       payload:(nullable NSString *)payload 
                   lossPayload:(nullable NSString *)lossPayload
                          sent:(BOOL)sent
                     createdAt:(int64_t)createdAt
                     updatedAt:(int64_t)updatedAt;
@end

@implementation CLXCachedWinLossEvent
- (instancetype)initWithEventId:(NSString *)eventId 
                     auctionId:(NSString *)auctionId 
                         bidId:(NSString *)bidId 
                         state:(NSString *)state 
                   endpointUrl:(NSString *)endpointUrl 
                       payload:(nullable NSString *)payload 
                   lossPayload:(nullable NSString *)lossPayload
                          sent:(BOOL)sent
                     createdAt:(int64_t)createdAt
                     updatedAt:(int64_t)updatedAt {
    self = [super init];
    if (self) {
        _eventId = [eventId copy];
        _auctionId = [auctionId copy];
        _bidId = [bidId copy];
        _state = [state copy];
        _endpointUrl = [endpointUrl copy];
        _payload = [payload copy];
        _lossPayload = [lossPayload copy];
        _sent = sent;
        _createdAt = createdAt;
        _updatedAt = updatedAt;
    }
    return self;
}
@end

// State constants
static NSString *const kStateNew = @"NEW";
static NSString *const kStateLoaded = @"LOADED";
static NSString *const kStateWin = @"WIN";
static NSString *const kStateLoss = @"LOSS";

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
    // Get all cached events and retry sending
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

- (void)sendEvent:(NSString *)auctionId
            bidId:(NSString *)bidId
            event:(CLXBidLifecycleEvent *)event
       lossReason:(nullable NSNumber *)lossReason
   winnerBidPrice:(double)winnerBidPrice {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CLXBidResponseBid *bid = [self.auctionBidManager getBid:auctionId bidId:bidId];
        
        if (!bid) {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] No bid found for event: %@", bidId]];
            return;
        }
        
        // Determine loaded bid price based on event type
        double loadedBidPrice = winnerBidPrice;
        if (event.type == CLXBidLifecycleEventTypeLoadSuccess || event.type == CLXBidLifecycleEventTypeRenderSuccess) {
            loadedBidPrice = bid.price;
        }
        
        // Build payload using field resolver with lifecycle event
        NSDictionary<NSString *, id> *payload = [self.winLossFieldResolver 
            buildWinLossPayloadWithAuctionId:auctionId
                                          bid:bid
                                   lossReason:lossReason
                                        event:event
                               loadedBidPrice:loadedBidPrice];
        
        if (payload) {
            NSString *eventName = event.notificationType.length > 0 ? event.notificationType : @"BidReceived";
            [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossTracker] %@: %@ ($%.2f) [%@]", 
                               eventName, bidId, loadedBidPrice, event.urlType]];
            
            // Log complete payload structure for testing/debugging
            NSError *jsonError;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload 
                                                               options:NSJSONWritingPrettyPrinted 
                                                                 error:&jsonError];
            if (jsonData) {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self.logger debug:[NSString stringWithFormat:@"📦 [WinLossTracker] Complete payload:\n%@", jsonString]];
                
                // Log presence of critical fields
                BOOL hasBid = payload[@"bid"] != nil;
                BOOL hasLossReasonCode = payload[@"lossReasonCode"] != nil;
                BOOL hasDeviceTypeCode = payload[@"deviceTypeCode"] != nil;
                [self.logger debug:[NSString stringWithFormat:@"✅ [WinLossTracker] Critical fields - bid: %@, lossReasonCode: %@, deviceTypeCode: %@", 
                                   hasBid ? @"YES" : @"NO",
                                   hasLossReasonCode ? @"YES" : @"NO", 
                                   hasDeviceTypeCode ? @"YES" : @"NO"]];
            }
            
            // Fire event immediately (no state management)
            [self trackWinLoss:payload auctionId:auctionId bidId:bidId];
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] %@ payload failed: %@", 
                               event.notificationType, bidId]];
        }
    });
}

// REMOVED: saveBidsAsNew() - Events fire immediately when they occur
// REMOVED: convertUnfinishedBidsToLoss() - No state management in simplified implementation

- (void)sendLossNotificationsForLosingBids:(NSString *)auctionId
                             winningBidId:(NSString *)winningBidId
                                  allBids:(NSArray<CLXBidResponseBid *> *)allBids {
    
    if (!auctionId || !winningBidId || !allBids || allBids.count == 0) {
        return;
    }
    
    // Set winner in win/loss tracker
    [self setWinner:auctionId winningBidId:winningBidId];
    
    // Get winner bid price for LOST_TO_HIGHER_BID notifications
    CLXBidResponseBid *winningBid = nil;
    for (CLXBidResponseBid *bid in allBids) {
        if ([bid.id isEqualToString:winningBidId]) {
            winningBid = bid;
            break;
        }
    }
    double winnerBidPrice = winningBid ? winningBid.price : -1.0;
    
    NSInteger lossCount = 0;
    for (CLXBidResponseBid *bid in allBids) {
        // Skip the winner
        if ([bid.id isEqualToString:winningBidId]) {
            continue;
        }
        
        // Send server-side loss notification using sendEvent()
        if (bid.id) {
            [self setBidLoadResult:auctionId 
                             bidId:bid.id 
                           success:NO 
                        lossReason:@(CLXLossReasonLostToHigherBid)];
            
            // Use sendEvent() with LOSS event type
            [self sendEvent:auctionId
                      bidId:bid.id
                      event:[CLXBidLifecycleEvent lossEvent]
                 lossReason:@(CLXLossReasonLostToHigherBid)
             winnerBidPrice:winnerBidPrice];
            
            lossCount++;
        }
    }
    
    if (lossCount > 0) {
        [self.logger debug:[NSString stringWithFormat:@"📤 [WinLossTracker] Sent %ld LOSS events (LOST_TO_HIGHER_BID)", (long)lossCount]];
    }
}

- (void)clearAuction:(NSString *)auctionId {
    [self.auctionBidManager clearAuction:auctionId];
}

#pragma mark - Helper Methods

// REMOVED: stateForEvent() - No longer needed (state machine removed)

/**
 * Converts dictionary to JSON string
 */
- (nullable NSString *)jsonStringFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary) {
        return nil;
    }
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    if (error || !jsonData) {
        [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] Failed to serialize dictionary: %@", error]];
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark - Database Management

- (void)createWinLossTableIfNeeded {
    if (![self.database tableExists:@"cached_win_loss_events_table"]) {
        // Simplified schema: id, auctionId, bidId, payload, createdAt
        NSString *createTableSQL = @"CREATE TABLE cached_win_loss_events_table ("
                                   @"id INTEGER PRIMARY KEY AUTOINCREMENT,"
                                   @"auctionId TEXT NOT NULL,"
                                   @"bidId TEXT NOT NULL,"
                                   @"payload TEXT NOT NULL,"
                                   @"createdAt INTEGER NOT NULL"
                                   @");";
        
        BOOL success = [self.database executeSQL:createTableSQL];
        if (success) {
            [self.logger debug:@"✅ Win/loss events table created (simplified schema)"];
        } else {
            [self.logger error:@"❌ Failed to create win/loss events table"];
        }
    } else {
        // Migrate from old complex schema to new simplified schema
        [self migrateToSimplifiedSchema];
    }
}

- (void)migrateToSimplifiedSchema {
    // Check current schema to determine if migration is needed
    NSString *pragmaSQL = @"PRAGMA table_info(cached_win_loss_events_table);";
    NSArray<NSDictionary *> *columns = [self.database executeQuery:pragmaSQL];
    
    BOOL hasStateColumn = NO;
    BOOL hasSimplifiedSchema = NO;
    
    for (NSDictionary *column in columns) {
        NSString *columnName = column[@"name"];
        if ([columnName isEqualToString:@"state"]) {
            hasStateColumn = YES;
        }
    }
    
    // Check if already using simplified schema (no state column)
    hasSimplifiedSchema = !hasStateColumn && columns.count == 5;
    
    if (hasSimplifiedSchema) {
        [self.logger debug:@"✅ Database already using simplified schema"];
        return;
    }
    
    [self.logger debug:@"🔄 Migrating to simplified schema..."];
    
    // Create new simplified table
    NSString *createNewTableSQL = @"CREATE TABLE cached_win_loss_events_table_new ("
                                  @"id INTEGER PRIMARY KEY AUTOINCREMENT,"
                                  @"auctionId TEXT NOT NULL,"
                                  @"bidId TEXT NOT NULL,"
                                  @"payload TEXT NOT NULL,"
                                  @"createdAt INTEGER NOT NULL"
                                  @");";
    
    if ([self.database executeSQL:createNewTableSQL]) {
        // Copy existing events (only those with valid payload)
        // Discard state/lossPayload/sent/updatedAt - no longer needed
        NSString *copySQL = @"INSERT INTO cached_win_loss_events_table_new "
                           @"(auctionId, bidId, payload, createdAt) "
                           @"SELECT "
                           @"COALESCE(auctionId, ''), "
                           @"COALESCE(bidId, ''), "
                           @"COALESCE(payload, '{}'), "
                           @"COALESCE(createdAt, strftime('%s', 'now') * 1000) "
                           @"FROM cached_win_loss_events_table "
                           @"WHERE payload IS NOT NULL AND payload != '';";
        
        [self.database executeSQL:copySQL];
        
        // Drop old table
        [self.database executeSQL:@"DROP TABLE cached_win_loss_events_table;"];
        
        // Rename new table
        [self.database executeSQL:@"ALTER TABLE cached_win_loss_events_table_new RENAME TO cached_win_loss_events_table;"];
        
        [self.logger debug:@"✅ Database migrated to simplified schema successfully"];
    } else {
        [self.logger error:@"❌ Failed to create new simplified table during migration"];
    }
}

#pragma mark - Private Methods

/**
 * Sends win/loss payload to server
 */
- (void)trackWinLoss:(NSDictionary<NSString *, id> *)payload
           auctionId:(NSString *)auctionId
               bidId:(NSString *)bidId {
    
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
    
    // Convert payload to JSON string
    NSString *payloadJson = [self jsonStringFromDictionary:payload];
    if (!payloadJson) {
        [self.logger error:@"❌ [WinLossTracker] Failed to serialize payload"];
        return;
    }
    
    // Save to database first for retry capability
    NSNumber *eventId = [self saveEvent:auctionId bidId:bidId payload:payloadJson];
    
    // Then try to send
    [self.networkService sendWithAppKey:appKey
                            endpointUrl:endpoint
                                payload:payload
                             completion:^(BOOL success, NSError * _Nullable error) {
        
        if (success) {
            // Delete from database on success
            if (eventId) {
                [self deleteEventWithId:[eventId stringValue]];
            }
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossTracker] Send failed: %@", 
                               error ? error.localizedDescription : @"Unknown error"]];
            // Keep in database for retry
        }
    }];
}

/**
 * Saves event to database (simplified schema)
 * Returns the event ID for later deletion on success
 */
- (nullable NSNumber *)saveEvent:(NSString *)auctionId
                           bidId:(NSString *)bidId
                         payload:(NSString *)payloadJson {
    if (!auctionId || !bidId || !payloadJson) {
        [self.logger error:@"❌ [WinLossTracker] Cannot save event with nil parameters"];
        return nil;
    }
    
    int64_t now = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
    
    NSString *insertSQL = @"INSERT INTO cached_win_loss_events_table "
                          @"(auctionId, bidId, payload, createdAt) "
                          @"VALUES (?, ?, ?, ?);";
    NSArray *parameters = @[auctionId, bidId, payloadJson, @(now)];
    
    BOOL success = [self.database executeSQL:insertSQL withParameters:parameters];
    if (success) {
        // Get the last inserted row ID
        NSString *selectSQL = @"SELECT last_insert_rowid();";
        NSArray *rows = [self.database executeQuery:selectSQL];
        if (rows.count > 0) {
            NSDictionary *row = rows[0];
            NSNumber *eventId = row[@"last_insert_rowid()"];
            [self.logger debug:[NSString stringWithFormat:@"💾 [WinLossTracker] Saved event ID: %@", eventId]];
            return eventId;
        }
    } else {
        [self.logger error:@"❌ [WinLossTracker] Failed to save event to database"];
    }
    
    return nil;
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
    // Simplified schema: only id, auctionId, bidId, payload, createdAt
    NSString *selectSQL = @"SELECT id, auctionId, bidId, payload, createdAt "
                          @"FROM cached_win_loss_events_table;";
    NSArray<NSDictionary *> *rows = [self.database executeQuery:selectSQL];
    
    NSMutableArray<CLXCachedWinLossEvent *> *events = [NSMutableArray array];
    for (NSDictionary *row in rows) {
        NSString *eventId = [row[@"id"] stringValue];
        NSString *auctionId = row[@"auctionId"] ?: @"";
        NSString *bidId = row[@"bidId"] ?: @"";
        NSString *payload = row[@"payload"] ?: @"";
        int64_t createdAt = [row[@"createdAt"] longLongValue];
        
        // Use simplified initializer (no state, lossPayload, sent, updatedAt)
        CLXCachedWinLossEvent *event = [[CLXCachedWinLossEvent alloc] initWithEventId:eventId 
                                                                         auctionId:auctionId
                                                                             bidId:bidId
                                                                             state:@""
                                                                       endpointUrl:@""
                                                                           payload:payload
                                                                       lossPayload:nil
                                                                              sent:NO
                                                                         createdAt:createdAt
                                                                         updatedAt:createdAt];
        [events addObject:event];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Retrieved %lu pending cached events", (unsigned long)events.count]];
    return [events copy];
}

// REMOVED: getUnfinishedBids() - No state tracking in simplified implementation

// REMOVED: insertEventWithAuctionId() - Old state-based insert, replaced with simpler cacheEvent()

// REMOVED: updateBidState() - No state management in simplified implementation
// REMOVED: markEventAsSent() - No sent flag in simplified schema
// REMOVED: markEventAsUnsent() - No sent flag in simplified schema

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


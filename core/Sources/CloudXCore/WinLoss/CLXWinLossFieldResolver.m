/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossFieldResolver.m
 * @brief Implementation of Win/Loss field resolver
 */

#import <CloudXCore/CLXWinLossFieldResolver.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBidLifecycleEvent.h>
#import <CloudXCore/CLXSystemInformation.h>

// Template placeholders for dynamic field resolution
static NSString *const kPlaceholderAuctionPrice = @"${AUCTION_PRICE}";
static NSString *const kPlaceholderAuctionLoss = @"${AUCTION_LOSS}";

@interface CLXWinLossFieldResolver ()
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *winLossPayloadMapping;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) CLXTrackingFieldResolver *trackingFieldResolver;
@end

@implementation CLXWinLossFieldResolver

- (instancetype)init {
    return [self initWithPayloadMapping:nil];
}

- (instancetype)initWithPayloadMapping:(NSDictionary<NSString *, NSString *> *)payloadMapping {
    // Use shared instance for backward compatibility in production
    return [self initWithPayloadMapping:payloadMapping 
                   trackingFieldResolver:[CLXTrackingFieldResolver shared]];
}

- (instancetype)initWithPayloadMapping:(NSDictionary<NSString *, NSString *> *)payloadMapping
                  trackingFieldResolver:(CLXTrackingFieldResolver *)trackingFieldResolver {
    self = [super init];
    if (self) {
        _winLossPayloadMapping = [payloadMapping copy];
        _trackingFieldResolver = trackingFieldResolver;
        _logger = [[CLXLogger alloc] initWithCategory:@"WinLossFieldResolver"];
    }
    return self;
}

- (void)setConfig:(CLXSDKConfigResponse *)config {
    // Extract winLossNotificationPayloadConfig from server config
    self.winLossPayloadMapping = config.winLossNotificationPayloadConfig;
    
    [self.logger debug:[NSString stringWithFormat:@"Config set - mapping available: %@, fields: %lu", 
                       self.winLossPayloadMapping ? @"YES" : @"NO",
                       (unsigned long)self.winLossPayloadMapping.count]];
}


- (nullable NSDictionary<NSString *, id> *)buildWinLossPayloadWithAuctionId:(NSString *)auctionId
                                                                        bid:(nullable CLXBidResponseBid *)bid
                                                                 lossReason:(nullable NSNumber *)lossReason
                                                                      event:(CLXBidLifecycleEvent *)event
                                                              loadedBidPrice:(double)loadedBidPrice {
    
    // Return nil if no payload mapping configured
    NSDictionary<NSString *, NSString *> *payloadMapping = self.winLossPayloadMapping;
    
    if (!payloadMapping) {
        [self.logger debug:@"No payload mapping configured, returning nil"];
        return nil;
    }
    
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionary];
    
    // Resolve each field in the payload mapping
    [payloadMapping enumerateKeysAndObjectsUsingBlock:^(NSString *payloadKey, NSString *fieldPath, BOOL *stop) {
        id resolvedValue = [self resolveWinLossFieldWithAuctionId:auctionId
                                                              bid:bid
                                                       lossReason:lossReason
                                                        fieldPath:fieldPath
                                                            event:event
                                                   loadedBidPrice:loadedBidPrice];
        
        // Only add non-nil and non-empty values to result 
        // Filter out nil values
        if (!resolvedValue) {
            [self.logger debug:[NSString stringWithFormat:@"[WinLossFieldResolver] Field '%@' -> '%@' resolved to nil", payloadKey, fieldPath]];
            return;
        }
        
        // Filter out empty strings
        if ([resolvedValue isKindOfClass:[NSString class]] && [(NSString *)resolvedValue length] == 0) {
            [self.logger debug:[NSString stringWithFormat:@"[WinLossFieldResolver] Field '%@' -> '%@' resolved to empty string", payloadKey, fieldPath]];
            return;
        }
        
        result[payloadKey] = resolvedValue;
    }];
    
    [self.logger debug:[NSString stringWithFormat:@"Built payload with %lu fields for %@ event (type: %@)", 
                       (unsigned long)result.count, event.notificationType.length > 0 ? event.notificationType : @"BidReceived", event.urlType]];
    
    if (result.count == 0) {
        [self.logger debug:[NSString stringWithFormat:@"[WinLossFieldResolver] Empty payload for %@ event - auction: %@, bid: %@", 
                           event.notificationType, auctionId, bid.id]];
    }
    return [result copy];
}

#pragma mark - Private Methods

/**
 * Resolves individual win/loss fields with lifecycle event support
 */
- (nullable id)resolveWinLossFieldWithAuctionId:(NSString *)auctionId
                                            bid:(nullable CLXBidResponseBid *)bid
                                     lossReason:(nullable NSNumber *)lossReason
                                      fieldPath:(NSString *)fieldPath
                                          event:(CLXBidLifecycleEvent *)event
                                 loadedBidPrice:(double)loadedBidPrice {
    
    // Handle new dynamic fields for lifecycle events
    if ([fieldPath isEqualToString:@"notification"]) {
        // Return notification type from lifecycle event (camelCase)
        return event.notificationType.length > 0 ? event.notificationType : nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.[loadSuccess|renderSuccess|loss]"]) {
        // Return notification type in snake_case format for server compatibility
        // Convert camelCase to snake_case: loadSuccess -> load_success, renderSuccess -> render_success
        NSString *notificationType = event.notificationType;
        if ([notificationType isEqualToString:@"loadSuccess"]) {
            return @"loadSuccess";
        } else if ([notificationType isEqualToString:@"renderSuccess"]) {
            return @"renderSuccess";
        } else if ([notificationType isEqualToString:@"loss"]) {
            return @"loss";
        }
        return notificationType; // Fallback: return as-is
        
    } else if ([fieldPath isEqualToString:@"sdk.[bid.nurl|bid.lurl]"]) {
        // Dynamic URL resolution based on event's urlType (alternative syntax)
        NSString *urlType = event.urlType;
        NSString *url = nil;
        
        if ([urlType isEqualToString:@"nurl"]) {
            url = bid.nurl;
        } else if ([urlType isEqualToString:@"lurl"]) {
            url = bid.lurl;
        } else if ([urlType isEqualToString:@"burl"]) {
            url = bid.burl;
        }
        
        // Return raw URL with macros INTACT - server will hydrate
        // Zero client-side URL hydration - macros are resolved server-side
        if (url && url.length > 0) {
            return [self replaceUrlTemplatesInUrl:url
                                       lossReason:lossReason
                                   loadedBidPrice:loadedBidPrice];
        }

        return url;
        
    } else if ([fieldPath isEqualToString:@"sdk.win"]) {
        // Return "win" only for win events (loadSuccess, renderSuccess, or reward)
        if (event.type == CLXBidLifecycleEventTypeLoadSuccess || 
            event.type == CLXBidLifecycleEventTypeRenderSuccess ||
            event.type == CLXBidLifecycleEventTypeReward) {
            return @"win";
        }
        return nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.loss"]) {
        // Return "loss" only for loss events
        if (event.type == CLXBidLifecycleEventTypeLoss) {
            return @"loss";
        }
        return nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.reward"]) {
        // Return "reward" only for reward events
        if (event.type == CLXBidLifecycleEventTypeReward) {
            return @"reward";
        }
        return nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.[win|loss]"]) {
        // Return "win" or "loss" based on event type (reward counts as win)
        if (event.type == CLXBidLifecycleEventTypeLoadSuccess || 
            event.type == CLXBidLifecycleEventTypeRenderSuccess ||
            event.type == CLXBidLifecycleEventTypeReward) {
            return @"win";
        } else if (event.type == CLXBidLifecycleEventTypeLoss) {
            return @"loss";
        }
        return nil;
        
    } else if ([fieldPath isEqualToString:@"lossReason"]) {
        // Return numeric loss reason value (for payload)
        return lossReason;
        
    } else if ([fieldPath isEqualToString:@"sdk.deviceTypeCode"]) {
        // Return numeric loss reason value (for payload)
        NSInteger deviceTypeAsInt = [CLXSystemInformation shared].deviceType;
        return @(deviceTypeAsInt);
        
    } else if ([fieldPath isEqualToString:@"sdk.lossReasonCode"]) {
        // Return human-readable loss reason description
        if (!lossReason) {
            return nil;
        }
        switch (lossReason.integerValue) {
            case 0:  // CLXLossReasonBidWon
                return @(lossReason.integerValue);
            case 1:  // CLXLossReasonInternalError
                return @(lossReason.integerValue);
            default:
                return @(lossReason.integerValue);
        }
        
    } else if ([fieldPath isEqualToString:@"sdk.sdk"]) {
        return @"sdk";
        
    } else if ([fieldPath isEqualToString:@"auctionId"]) {
        return auctionId;
        
    } else if ([fieldPath isEqualToString:@"bidId"]) {
        return bid.id;
        
    } else if ([fieldPath isEqualToString:@"seatbid[0].bid[0]"]) {
        return [bid toDictionary];
        
    } else if ([fieldPath isEqualToString:@"bid.id"]) {
        return bid.id;
        
    } else if ([fieldPath isEqualToString:@"bid.price"]) {
        return @(bid.price);
        
    } else {
        // Delegate to injected tracking field resolver for other fields (bid.*, bidRequest.*, config.*)
        return [self.trackingFieldResolver resolveField:fieldPath forAuction:auctionId];
    }
}

/**
 * Resolves individual win/loss fields from bid data and lifecycle events
 * (Legacy method for backwards compatibility)
 */
- (nullable id)resolveWinLossFieldWithAuctionId:(NSString *)auctionId
                                            bid:(nullable CLXBidResponseBid *)bid
                                     lossReason:(nullable NSNumber *)lossReason
                                      fieldPath:(NSString *)fieldPath
                                          isWin:(BOOL)isWin
                                 loadedBidPrice:(double)loadedBidPrice {
    
    // Resolve field based on path
    if ([fieldPath isEqualToString:@"sdk.win"]) {
        return isWin ? @"win" : nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.loss"]) {
        return !isWin ? @"loss" : nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.lossReasonCode"]) {
        // // Return human-readable loss reason description
        if (!lossReason) {
            return nil;
        }
        switch (lossReason.integerValue) {
            case 0:  // CLXLossReasonBidWon
                return @(lossReason.integerValue);
            case 1:  // CLXLossReasonInternalError
                return @(lossReason.integerValue);
            default:
                return @(lossReason.integerValue);
        }
        
    } else if ([fieldPath isEqualToString:@"sdk.[win|loss]"]) {
        return isWin ? @"win" : @"loss";
        
    } else if ([fieldPath isEqualToString:@"sdk.sdk"]) {
        return @"sdk";
        
    } else if ([fieldPath isEqualToString:@"sdk.[bid.nurl|bid.lurl]"]) {
         // Return raw URL with macros INTACT - server will hydrate
        // Zero client-side URL hydration - macros are resolved server-side
        NSString *url = nil;
        if (isWin) {
            url = bid.nurl;
        } else {
            url = bid.lurl;
        }
        
        if (url && url.length > 0) {
            return [self replaceUrlTemplatesInUrl:url
                                            isWin:isWin
                                       lossReason:lossReason
                                   loadedBidPrice:loadedBidPrice];
        }
        
        return url;
        
    } else if ([fieldPath isEqualToString:@"auctionId"]) {
        // Return the auction ID directly
        return auctionId;
        
    } else if ([fieldPath isEqualToString:@"bidId"]) {
        // Return the bid ID from the bid
        return bid.id;
        
    } else if ([fieldPath isEqualToString:@"bid.id"]) {
        // Return the bid ID from the bid (alternative field path format)
        return bid.id;
        
    } else if ([fieldPath isEqualToString:@"bid.price"]) {
        // Return the bid price from the bid
        return @(bid.price);
        
    } else if ([fieldPath isEqualToString:@"eventType"]) {
        // Return the event type based on win/loss status
        return isWin ? @"win" : @"loss";
        
    } else if ([fieldPath isEqualToString:@"seatbid[0].bid[0]"]) {
        return [bid toDictionary];
       
    } else if ([fieldPath isEqualToString:@"sdk.deviceTypeCode"]) {
        // Return numeric loss reason value (for payload)
        NSInteger deviceTypeAsInt = [CLXSystemInformation shared].deviceType;
        return @(deviceTypeAsInt);
        
    } else {
        // Delegate to injected tracking field resolver for other fields
        return [self.trackingFieldResolver resolveField:fieldPath forAuction:auctionId];
    }
}

/**
 * URL macro replacement method (no longer used - kept for reference)
 * 
 * URLs are now sent to the server with macros INTACT (${AUCTION_PRICE}, ${AUCTION_LOSS}),
 * and the server performs macro substitution before firing the URLs.
 * 
 * URL template replacement for server-side hydration
 * but is never called (dead code).
 */
- (NSString *)replaceUrlTemplatesInUrl:(NSString *)url
                            lossReason:(nullable NSNumber *)lossReason
                        loadedBidPrice:(double)loadedBidPrice {
    // No longer performing client-side macro replacement
    // Server now handles ${AUCTION_PRICE} and ${AUCTION_LOSS} substitution
    return url;
}

/**
 * URL macro replacement method (no longer used - kept for reference)
 * (Legacy method signature with isWin parameter)
 */
- (NSString *)replaceUrlTemplatesInUrl:(NSString *)url
                                 isWin:(BOOL)isWin
                            lossReason:(nullable NSNumber *)lossReason
                        loadedBidPrice:(double)loadedBidPrice {
    // No longer performing client-side macro replacement
    // Server now handles ${AUCTION_PRICE} and ${AUCTION_LOSS} substitution
    return url;
}

@end

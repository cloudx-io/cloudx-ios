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
                                                              loadedBidPrice:(double)loadedBidPrice
                                                                      error:(nullable CLXError *)error {
    
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
                                                       payloadKey:payloadKey
                                                        fieldPath:fieldPath
                                                            event:event
                                                            error:error];
        
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
 * Resolves a single win/loss field.
 * Only handles WinLoss-specific fields; everything else delegates to CLXTrackingFieldResolver.
 */
- (nullable id)resolveWinLossFieldWithAuctionId:(NSString *)auctionId
                                            bid:(nullable CLXBidResponseBid *)bid
                                     lossReason:(nullable NSNumber *)lossReason
                                     payloadKey:(NSString *)payloadKey
                                      fieldPath:(NSString *)fieldPath
                                          event:(CLXBidLifecycleEvent *)event
                                          error:(nullable CLXError *)error {

    // notificationType and bid use payloadKey (server contract)
    if ([payloadKey isEqualToString:@"notificationType"]) {
        return event.notificationType;
    }

    if ([payloadKey isEqualToString:@"bid"]) {
        return bid.rawJSON;
    }

    // WinLoss-specific fieldPath cases
    if ([fieldPath isEqualToString:@"sdk.sdk"]) {
        return @"sdk";
    }

    if ([fieldPath isEqualToString:@"sdk.error"]) {
        if (!error) return nil;
        return @{
            @"code": [CLXError nameForCode:(CLXErrorCode)error.code],
            @"message": error.localizedDescription ?: @""
        };
    }

    if ([fieldPath isEqualToString:@"sdk.lossReasonCode"]) {
        return lossReason;
    }

    // Delegate everything else to TrackingFieldResolver (bid.*, bidRequest.*, config.*, sdk.*, etc.)
    return [self.trackingFieldResolver resolveField:auctionId field:fieldPath bidId:bid.id];
}

@end

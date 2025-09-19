/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossFieldResolver.m
 * @brief Implementation of Win/Loss field resolver matching Android exactly
 */

#import <CloudXCore/CLXWinLossFieldResolver.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXLogger.h>

// Template placeholders matching Android implementation
static NSString *const kPlaceholderAuctionPrice = @"${AUCTION_PRICE}";
static NSString *const kPlaceholderAuctionLoss = @"${AUCTION_LOSS}";

@interface CLXWinLossFieldResolver ()
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *winLossPayloadMapping;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXWinLossFieldResolver

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"WinLossFieldResolver"];
    }
    return self;
}

- (void)setConfig:(CLXSDKConfigResponse *)config {
    // TODO: Extract winLossNotificationPayloadConfig from server config when available
    // For now, use hardcoded mapping that matches Android's expected behavior
    self.winLossPayloadMapping = nil; // Will be set by server config later
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [WinLossFieldResolver] Config set - mapping available: %@", 
                       self.winLossPayloadMapping ? @"YES" : @"NO"]];
}

- (nullable NSDictionary<NSString *, id> *)buildWinLossPayloadWithAuctionId:(NSString *)auctionId
                                                                        bid:(nullable CLXBidResponseBid *)bid
                                                                 lossReason:(nullable NSNumber *)lossReason
                                                                      isWin:(BOOL)isWin
                                                              loadedBidPrice:(double)loadedBidPrice {
    
    // Return nil if no payload mapping configured (matches Android behavior)
    NSDictionary<NSString *, NSString *> *payloadMapping = self.winLossPayloadMapping;
    if (!payloadMapping) {
        [self.logger debug:@"📊 [WinLossFieldResolver] No payload mapping configured, returning nil"];
        return nil;
    }
    
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionary];
    
    // Resolve each field in the payload mapping (matches Android's forEach logic)
    [payloadMapping enumerateKeysAndObjectsUsingBlock:^(NSString *payloadKey, NSString *fieldPath, BOOL *stop) {
        id resolvedValue = [self resolveWinLossFieldWithAuctionId:auctionId
                                                              bid:bid
                                                       lossReason:lossReason
                                                        fieldPath:fieldPath
                                                            isWin:isWin
                                                   loadedBidPrice:loadedBidPrice];
        
        // Only add non-nil values to result (matches Android behavior)
        if (resolvedValue) {
            result[payloadKey] = resolvedValue;
        }
    }];
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossFieldResolver] Built payload with %lu fields for %@ event", 
                       (unsigned long)result.count, isWin ? @"WIN" : @"LOSS"]];
    
    return [result copy];
}

#pragma mark - Private Methods

/**
 * Resolves individual win/loss fields - matches Android's resolveWinLossField method exactly
 */
- (nullable id)resolveWinLossFieldWithAuctionId:(NSString *)auctionId
                                            bid:(nullable CLXBidResponseBid *)bid
                                     lossReason:(nullable NSNumber *)lossReason
                                      fieldPath:(NSString *)fieldPath
                                          isWin:(BOOL)isWin
                                 loadedBidPrice:(double)loadedBidPrice {
    
    // Match Android's switch statement exactly
    if ([fieldPath isEqualToString:@"sdk.win"]) {
        return isWin ? @"win" : nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.loss"]) {
        return !isWin ? @"loss" : nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.lossReason"]) {
        return lossReason;
        
    } else if ([fieldPath isEqualToString:@"sdk.[win|loss]"]) {
        return isWin ? @"win" : @"loss";
        
    } else if ([fieldPath isEqualToString:@"sdk.sdk"]) {
        return @"sdk";
        
    } else if ([fieldPath isEqualToString:@"sdk.[bid.nurl|bid.lurl]"]) {
        // Extract nurl/lurl from bid based on win/loss status (matches Android exactly)
        NSString *url = nil;
        if (isWin) {
            url = bid.nurl;
        } else {
            url = bid.lurl;
        }
        
        if (url) {
            return [self replaceUrlTemplatesInUrl:url
                                            isWin:isWin
                                       lossReason:lossReason
                                   loadedBidPrice:loadedBidPrice];
        }
        return nil;
        
    } else if ([fieldPath isEqualToString:@"sdk.loopIndex"]) {
        // Delegate to existing tracking field resolver for loop index
        id loopIndex = [[CLXTrackingFieldResolver shared] resolveField:fieldPath forAuction:auctionId];
        if ([loopIndex isKindOfClass:[NSString class]]) {
            return @([((NSString *)loopIndex) integerValue]);
        }
        return loopIndex;
        
    } else {
        // Delegate to existing tracking field resolver for other fields
        return [[CLXTrackingFieldResolver shared] resolveField:fieldPath forAuction:auctionId];
    }
}

/**
 * Replaces URL templates with actual values - matches Android's replaceUrlTemplates method exactly
 */
- (NSString *)replaceUrlTemplatesInUrl:(NSString *)url
                                 isWin:(BOOL)isWin
                            lossReason:(nullable NSNumber *)lossReason
                        loadedBidPrice:(double)loadedBidPrice {
    
    NSString *processedUrl = [url copy];
    
    // Replace ${AUCTION_PRICE} template (matches Android logic)
    if ([processedUrl containsString:kPlaceholderAuctionPrice]) {
        NSString *priceString = [NSString stringWithFormat:@"%.2f", loadedBidPrice];
        processedUrl = [processedUrl stringByReplacingOccurrencesOfString:kPlaceholderAuctionPrice 
                                                               withString:priceString];
    }
    
    // Replace ${AUCTION_LOSS} template for loss events only (matches Android logic)
    if ([processedUrl containsString:kPlaceholderAuctionLoss] && !isWin) {
        NSInteger lossReasonCode = lossReason ? lossReason.integerValue : 1; // Default to 1 like Android
        NSString *lossReasonString = [NSString stringWithFormat:@"%ld", (long)lossReasonCode];
        processedUrl = [processedUrl stringByReplacingOccurrencesOfString:kPlaceholderAuctionLoss 
                                                               withString:lossReasonString];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [WinLossFieldResolver] URL template replacement - Original: %@, Processed: %@", 
                       url, processedUrl]];
    
    return processedUrl;
}

@end

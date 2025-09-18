#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/CLXRillImpressionDefaultModel.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXRillImpressionProperties.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXLogger.h>


@interface CLXRillImpressionInitService ()

@end

@implementation CLXRillImpressionInitService

+ (NSString *)createDataStringWithRillImpressionModel:(CLXRillImpressionModel *)rillImpressionModel {
    static CLXLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[CLXLogger alloc] initWithCategory:@"RillImpressionInitService"];
    });
    
    // Use server-driven approach
    CLXTrackingFieldResolver *resolver = [CLXTrackingFieldResolver shared];
    
    // Set up tracking data in resolver
    // Use actual auction ID from bid response if available, fallback to account ID
    NSString *auctionId = rillImpressionModel.lastBidResponse.auctionId ?: rillImpressionModel.impModel.auctionID;
    if (!auctionId) {
        [logger debug:@"No auction ID available for server-driven tracking"];
        return @"";
    }
    
    [logger debug:[NSString stringWithFormat:@"Using auction ID for tracking: %@ (from %@)", 
                   auctionId, rillImpressionModel.lastBidResponse.auctionId ? @"bid response" : @"account ID"]];
    
    // Set session data
    [resolver setSessionConstData:rillImpressionModel.impModel.sessionID ?: @""
                       sdkVersion:@"1.0.0"
                       deviceType:DeviceTypeToString([CLXSystemInformation shared].deviceType)
                      abTestGroup:rillImpressionModel.impModel.testGroupName ?: @""];
    
    // Set loop index
    [resolver setLoopIndex:auctionId loopIndex:rillImpressionModel.loadBannerTimesCount];
    
    // Set bid response data if available
    if (rillImpressionModel.lastBidResponse && rillImpressionModel.lastBidResponse.bid) {
        [resolver saveLoadedBid:auctionId bidId:rillImpressionModel.lastBidResponse.bid.id ?: @""];
    }
    
    //Set server config
    if (rillImpressionModel.impModel.sdkConfig) {
        [logger debug:[NSString stringWithFormat:@"🔍 [SDK_CONFIG_DEBUG] SDK config available with %lu tracking fields: %@", 
                       (unsigned long)rillImpressionModel.impModel.sdkConfig.tracking.count, 
                       rillImpressionModel.impModel.sdkConfig.tracking]];
        [resolver setConfig:rillImpressionModel.impModel.sdkConfig];
    } else {
        [logger debug:@"⚠️ [SDK_CONFIG_DEBUG] No SDK config available in impression model"];
    }
    
    // Build payload using server-driven fields
    NSString *serverDrivenPayload = [resolver buildPayload:auctionId];
    if (serverDrivenPayload && serverDrivenPayload.length > 0) {
        [logger debug:@"Using server-driven tracking payload"];
        [logger debug:[NSString stringWithFormat:@"🔍 [PAYLOAD DEBUG] Raw payload before encryption: %@", serverDrivenPayload]];
        return serverDrivenPayload;
    }
    
    // Return empty string if no server config available
    [logger debug:@"No server tracking config - returning empty string"];
    return @"";
}

@end 

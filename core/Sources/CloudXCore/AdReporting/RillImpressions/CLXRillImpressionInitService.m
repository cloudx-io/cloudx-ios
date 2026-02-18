#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXBiddingConfig.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXVersion.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>


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
    NSString *appBundle = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
    NSString *pluginVersion = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCorePluginVersionKey];
    [resolver setSessionConstData:rillImpressionModel.impModel.sessionID ?: @""
                       sdkVersion:CLXSDKVersion
                    pluginVersion:pluginVersion
                   deviceTypeName:DeviceTypeToString([CLXSystemInformation shared].deviceType)
                   deviceTypeCode:[CLXSystemInformation shared].deviceType
                      abTestGroup:@""
                        appBundle:appBundle];
    
    //Set server config
    if (rillImpressionModel.impModel.sdkConfig) {
        [resolver setConfig:rillImpressionModel.impModel.sdkConfig];
    } else {
        [logger warn:@"[SDK_CONFIG_DEBUG] No SDK config available in impression model"];
    }

    NSString *bidId = rillImpressionModel.lastBidResponse.bid.id;
    NSString *serverDrivenPayload = [resolver buildPayload:auctionId bidId:bidId];
    if (serverDrivenPayload && serverDrivenPayload.length > 0) {
        [logger debug:@"Using server-driven tracking payload"];
        [logger debug:[NSString stringWithFormat:@"Raw payload before encryption: %@", serverDrivenPayload]];
        return serverDrivenPayload;
    }
    
    // Return empty string if no server config available
    [logger debug:@"No server tracking config - returning empty string"];
    return @"";
}

@end 

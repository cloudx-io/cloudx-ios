//
//  CLXVungleBaseFactory.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import "CLXVungleBaseFactory.h"

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <VungleAdsSDK/VungleAdsSDK.h>

@implementation CLXVungleBaseFactory

+ (NSString *)resolveVunglePlacementID:(NSDictionary<NSString *, NSString *> *)extras 
                            fallbackAdId:(NSString *)adId 
                                  logger:(CLXLogger *)logger {
    
    // Priority order for placement ID resolution:
    // 1. vungle_placement_id from extras
    // 2. placement_id from extras  
    // 3. adId as fallback
    
    NSString *placementId = extras[@"vungle_placement_id"];
    if (placementId && placementId.length > 0) {
        [logger logDebug:[NSString stringWithFormat:@"Using Vungle placement ID from extras: %@", placementId]];
        return placementId;
    }
    
    placementId = extras[@"placement_id"];
    if (placementId && placementId.length > 0) {
        [logger logDebug:[NSString stringWithFormat:@"Using placement ID from extras: %@", placementId]];
        return placementId;
    }
    
    [logger logDebug:[NSString stringWithFormat:@"Using adId as placement ID fallback: %@", adId]];
    return adId;
}

+ (BOOL)validateVungleInitialization:(CLXLogger *)logger {
    if (![VungleAds isInitialized]) {
        [logger logError:@"Vungle SDK is not initialized. Call VungleAds.initWithAppId before creating adapters."];
        return NO;
    }
    
    [logger logDebug:@"Vungle SDK initialization validated successfully"];
    return YES;
}

+ (nullable NSString *)extractBidPayloadFromADM:(NSString *)adm logger:(CLXLogger *)logger {
    if (!adm || adm.length == 0) {
        [logger logDebug:@"No ADM provided, using waterfall request"];
        return nil;
    }
    
    // Try to parse ADM as JSON to extract bid payload
    NSData *admData = [adm dataUsingEncoding:NSUTF8StringEncoding];
    if (!admData) {
        [logger logWarning:@"Unable to convert ADM to data, treating as waterfall"];
        return nil;
    }
    
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:admData options:0 error:&jsonError];
    
    if (jsonError || ![jsonObject isKindOfClass:[NSDictionary class]]) {
        [logger logDebug:@"ADM is not valid JSON, treating as waterfall request"];
        return nil;
    }
    
    NSDictionary *admDict = (NSDictionary *)jsonObject;
    NSString *bidPayload = admDict[@"bid_payload"] ?: admDict[@"bidPayload"];
    
    if (bidPayload && bidPayload.length > 0) {
        [logger logDebug:[NSString stringWithFormat:@"Extracted bid payload from ADM (length: %lu)", (unsigned long)bidPayload.length]];
        return bidPayload;
    }
    
    [logger logDebug:@"No bid payload found in ADM, using waterfall request"];
    return nil;
}

+ (NSDictionary *)createAdapterUserInfo:(NSString *)adId
                                  bidId:(NSString *)bidId
                            placementId:(NSString *)placementId
                                 extras:(NSDictionary<NSString *, NSString *> *)extras {
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    userInfo[@"adapter_type"] = @"vungle";
    userInfo[@"ad_id"] = adId ?: @"";
    userInfo[@"bid_id"] = bidId ?: @"";
    userInfo[@"placement_id"] = placementId ?: @"";
    userInfo[@"sdk_version"] = [VungleAds sdkVersion] ?: @"unknown";
    userInfo[@"creation_timestamp"] = @([[NSDate date] timeIntervalSince1970]);
    
    if (extras && extras.count > 0) {
        userInfo[@"extras"] = [extras copy];
    }
    
    return [userInfo copy];
}

@end

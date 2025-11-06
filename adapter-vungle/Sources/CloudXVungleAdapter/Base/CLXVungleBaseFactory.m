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
        [logger debug:[NSString stringWithFormat:@"Using Vungle placement ID from extras: %@", placementId]];
        return placementId;
    }
    
    placementId = extras[@"placement_id"];
    if (placementId && placementId.length > 0) {
        [logger debug:[NSString stringWithFormat:@"Using placement ID from extras: %@", placementId]];
        return placementId;
    }
    
    [logger debug:[NSString stringWithFormat:@"Using adId as placement ID fallback: %@", adId]];
    return adId;
}

+ (BOOL)validateVungleInitialization:(CLXLogger *)logger {
    if (![VungleAds isInitialized]) {
        [logger error:@"Vungle SDK is not initialized. Call VungleAds.initWithAppId before creating adapters."];
        return NO;
    }
    
    [logger debug:@"Vungle SDK initialization validated successfully"];
    return YES;
}

+ (nullable NSString *)extractBidPayloadFromADM:(NSString *)adm logger:(CLXLogger *)logger {
    if (!adm || adm.length == 0) {
        [logger debug:@"No ADM provided, using waterfall request"];
        return nil;
    }
    
    // Vungle SDK expects the ENTIRE ADM JSON string, not just the extracted adunit value
    // The ADM should be a JSON object like: {"version":2,"adunit":"..."}
    // Vungle SDK will parse this internally
    
    // Verify it's valid JSON before passing to Vungle
    NSData *admData = [adm dataUsingEncoding:NSUTF8StringEncoding];
    if (!admData) {
        [logger error:@"Unable to convert ADM to data"];
        return nil;
    }
    
    NSError *jsonError;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:admData options:0 error:&jsonError];
    
    if (jsonError || ![jsonObject isKindOfClass:[NSDictionary class]]) {
        // If ADM is not JSON, return as-is (might be raw payload for waterfall)
        [logger debug:@"ADM is not JSON, returning as-is"];
        return adm;
    }
    
    // ADM is valid JSON - return the entire JSON string to Vungle SDK
    [logger debug:[NSString stringWithFormat:@"Passing entire ADM JSON to Vungle SDK (length: %lu)", (unsigned long)adm.length]];
    return adm;
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

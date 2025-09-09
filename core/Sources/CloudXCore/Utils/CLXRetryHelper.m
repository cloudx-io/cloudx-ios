//
//  CLXRetryHelper.m
//  CloudXCore
//
//  Created by CloudX Team.
//

#import "CLXRetryHelper.h"
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXLogger.h>

@implementation CLXRetryHelper

+ (BOOL)shouldRetryForAdType:(CLXAdType)adType
                    settings:(CLXSettings *)settings
                      logger:(nullable CLXLogger *)logger
                failureBlock:(nullable void (^)(NSError *error))failureBlock {
    
    BOOL shouldRetry = NO;
    
    switch (adType) {
        case CLXAdTypeBanner:
            shouldRetry = [settings shouldEnableBannerRetries];
            break;
        case CLXAdTypeMrec:
            shouldRetry = [settings shouldEnableBannerRetries]; // MREC uses banner retry setting
            break;
        case CLXAdTypeInterstitial:
            shouldRetry = [settings shouldEnableInterstitialRetries];
            break;
        case CLXAdTypeRewarded:
            shouldRetry = [settings shouldEnableRewardedRetries];
            break;
        case CLXAdTypeNative:
            shouldRetry = [settings shouldEnableNativeRetries];
            break;
    }
    
    if (!shouldRetry) {
        NSString *adTypeName = [self nameForAdType:adType];
        if (logger) {
            [logger debug:[NSString stringWithFormat:@"🚫 [CLXRetryHelper] %@ retries disabled - not retrying", adTypeName]];
        }
        
        if (failureBlock) {
            NSError *error = [self retriesDisabledErrorForAdType:adType errorCode:1001];
            failureBlock(error);
        }
    }
    
    return shouldRetry;
}

+ (NSError *)retriesDisabledErrorForAdType:(CLXAdType)adType errorCode:(NSInteger)errorCode {
    NSString *adTypeName = [self nameForAdType:adType];
    NSString *description = [NSString stringWithFormat:@"%@ retries disabled", adTypeName];
    
    return [NSError errorWithDomain:@"CLXRetryHelper" 
                               code:errorCode 
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

+ (NSString *)nameForAdType:(CLXAdType)adType {
    switch (adType) {
        case CLXAdTypeBanner:
            return @"Banner";
        case CLXAdTypeMrec:
            return @"MREC";
        case CLXAdTypeInterstitial:
            return @"Interstitial";
        case CLXAdTypeRewarded:
            return @"Rewarded";
        case CLXAdTypeNative:
            return @"Native";
        default:
            return @"Unknown";
    }
}

@end

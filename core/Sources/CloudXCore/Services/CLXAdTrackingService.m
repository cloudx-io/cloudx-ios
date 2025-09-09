/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file AdTrackingService.m
 * @brief Implementation of advertising tracking functionality
 */

#import <CloudXCore/CLXAdTrackingService.h>
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>

@implementation CLXAdTrackingService

+ (BOOL)isIDFAAccessAllowed {
    if (@available(iOS 14, *)) {
        return ATTrackingManager.trackingAuthorizationStatus == ATTrackingManagerAuthorizationStatusAuthorized;
    } else {
        // For iOS 13 and below, check if advertising tracking is enabled
        // Note: This API is deprecated but still available for backward compatibility
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled;
        #pragma clang diagnostic pop
    }
}

+ (nullable NSString *)idfa {
    if (@available(iOS 14, *)) {
        return ATTrackingManager.trackingAuthorizationStatus == ATTrackingManagerAuthorizationStatusAuthorized ? 
               [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString : nil;
    } else {
        // For iOS 13 and below, check if advertising tracking is enabled
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled ? 
               [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString : nil;
        #pragma clang diagnostic pop
    }
}

+ (BOOL)dnt {
    if (@available(iOS 14, *)) {
        return ATTrackingManager.trackingAuthorizationStatus != ATTrackingManagerAuthorizationStatusAuthorized;
    } else {
        // For iOS 13 and below, check if advertising tracking is enabled
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return ![ASIdentifierManager sharedManager].isAdvertisingTrackingEnabled;
        #pragma clang diagnostic pop
    }
}

@end 
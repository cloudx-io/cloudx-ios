/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file URLProvider.m
 * @brief Implementation of URL provider functionality
 */

#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@implementation CLXURLProvider

+ (NSURL *)initApiUrl {
    static NSString *const devInitApiUrl = @"https://pro-dev.cloudx.io/sdk";
    static NSString *const stagingInitApiUrl = @"https://pro-stage.cloudx.io/sdk";
    static NSString *const prodInitApiUrl = @"https://pro.cloudx.io/sdk";
    
#if DEBUG
    // Check for demo app environment selection
    NSString *environment = [[NSUserDefaults standardUserDefaults] stringForKey:@"CLXDemoEnvironment"];
    if ([environment isEqualToString:@"staging"]) {
        return [NSURL URLWithString:stagingInitApiUrl];
    } else if ([environment isEqualToString:@"production"]) {
        return [NSURL URLWithString:prodInitApiUrl];
    } else if ([environment isEqualToString:@"dev"]) {
        return [NSURL URLWithString:devInitApiUrl];
    }
    
    // Default to DEV in debug builds
    return [NSURL URLWithString:devInitApiUrl];
#endif
    
    return [NSURL URLWithString:prodInitApiUrl];
}

+ (NSString *)auctionApiUrl {
    return @"https://au-dev.cloudx.io/openrtb2/auction";
}

+ (NSString *)metricsApiUrl {
    return @"https://ads.cloudx.io/metrics";
}

@end 

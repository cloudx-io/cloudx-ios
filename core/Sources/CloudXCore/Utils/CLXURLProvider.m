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
    static NSString *const prodInitApiUrl = @"https://pro-dev.cloudx.io/sdk";
    
#if DEBUG
    NSString *urlString = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreCloudXInitURLKey];
    if (urlString.length > 0) {
        return [NSURL URLWithString:urlString];
    }
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
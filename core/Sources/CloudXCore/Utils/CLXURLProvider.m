/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file URLProvider.m
 * @brief Implementation of URL provider functionality
 */

#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

// MARK: - Environment URLs
static NSString *const kDevInitURL = @"https://pro-dev.cloudx.io/sdk";
static NSString *const kStagingInitURL = @"https://pro-stage.cloudx.io/sdk";
static NSString *const kProductionInitURL = @"https://pro.cloudx.io/sdk";

// MARK: - User Defaults Key
static NSString *const kEnvironmentKey = @"CLXEnvironment";

@implementation CLXURLProvider

+ (NSURL *)initApiUrl {
    return [NSURL URLWithString:[self initializationURL]];
}

+ (NSString *)auctionApiUrl {
    // Auction URLs now come from SDK response only
    NSLog(@"⚠️ [CLXURLProvider] auctionApiUrl is deprecated - URLs come from SDK response");
    return nil;
}

+ (NSString *)metricsApiUrl {
    // Metrics URLs now come from SDK response only
    NSLog(@"⚠️ [CLXURLProvider] metricsApiUrl is deprecated - URLs come from SDK response");
    return nil;
}

// MARK: - Private Helper Methods

+ (NSString *)initializationURL {
#ifdef DEBUG
    // In DEBUG builds, check user preference
    NSString *environment = [[NSUserDefaults standardUserDefaults] stringForKey:kEnvironmentKey];
    
    if ([environment isEqualToString:@"staging"]) {
        return kStagingInitURL;
    } else if ([environment isEqualToString:@"production"]) {
        return kProductionInitURL;
    } else {
        // Default to dev in DEBUG builds
        return kDevInitURL;
    }
#else
    // Production builds always use production
    return kProductionInitURL;
#endif
}

+ (NSString *)environmentName {
#ifdef DEBUG
    NSString *environment = [[NSUserDefaults standardUserDefaults] stringForKey:kEnvironmentKey];
    
    if ([environment isEqualToString:@"staging"]) {
        return @"staging";
    } else if ([environment isEqualToString:@"production"]) {
        return @"production";
    } else {
        return @"development";
    }
#else
    return @"production";
#endif
}

+ (void)setEnvironment:(NSString *)environment {
#ifdef DEBUG
    // Validate environment
    NSArray *validEnvironments = @[@"dev", @"staging", @"production"];
    if (![validEnvironments containsObject:environment]) {
        NSLog(@"⚠️ [CLXURLProvider] Invalid environment '%@'. Valid options: %@", 
              environment, validEnvironments);
        return;
    }
    
    // Store the environment preference
    [[NSUserDefaults standardUserDefaults] setObject:environment forKey:kEnvironmentKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"✅ [CLXURLProvider] Environment set to: %@", environment);
#else
    // Ignored in production builds
    NSLog(@"⚠️ [CLXURLProvider] Environment switching disabled in production builds");
#endif
}

@end 

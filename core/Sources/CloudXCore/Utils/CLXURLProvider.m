/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file URLProvider.m
 * @brief Implementation of URL provider functionality
 */

#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXLogger.h>

// MARK: - Environment URLs
static NSString *const kDevInitURL = @"https://provisioning-dev.cloudx.io/sdk";
static NSString *const kStagingInitURL = @"https://pro-stage.cloudx.io/sdk";
static NSString *const kProductionInitURL = @"https://pro.cloudx.io/sdk";

// MARK: - User Defaults Key (Internal use only)
static NSString *const kEnvironmentKey = @"CLXEnvironment";

// MARK: - Internal Override Key (for CloudX internal testing only)
static NSString *const kInternalEnvironmentOverrideKey = @"CLXCore_Internal_EnvironmentOverride";

@implementation CLXURLProvider

+ (NSURL *)initApiUrl {
    return [NSURL URLWithString:[self initializationURL]];
}

+ (NSString *)auctionApiUrl {
    // Auction URLs now come from SDK response only
    [[CLXLogger shared] info:@"[CLXURLProvider] auctionApiUrl is deprecated - URLs come from SDK response"];
    return nil;
}

+ (NSString *)metricsApiUrl {
    // Metrics URLs now come from SDK response only
    [[CLXLogger shared] info:@"[CLXURLProvider] metricsApiUrl is deprecated - URLs come from SDK response"];
    return nil;
}

// MARK: - Private Helper Methods

+ (NSString *)initializationURL {
    // Check for internal override (CloudX internal testing only)
    NSString *internalOverride = [[NSUserDefaults standardUserDefaults] stringForKey:kInternalEnvironmentOverrideKey];
    
    if ([internalOverride isEqualToString:@"dev"]) {
        [[CLXLogger shared] info:@"[CLXURLProvider] Using DEV environment (internal override)"];
        return kDevInitURL;
    } else if ([internalOverride isEqualToString:@"staging"]) {
        [[CLXLogger shared] info:@"[CLXURLProvider] Using STAGING environment (internal override)"];
        return kStagingInitURL;
    }
    
    // Default: Always use production for all builds
    return kProductionInitURL;
}

+ (NSString *)environmentName {
    NSString *internalOverride = [[NSUserDefaults standardUserDefaults] stringForKey:kInternalEnvironmentOverrideKey];
    
    if ([internalOverride isEqualToString:@"dev"]) {
        return @"development";
    } else if ([internalOverride isEqualToString:@"staging"]) {
        return @"staging";
    }
    
    return @"production";
}

+ (void)setEnvironment:(NSString *)environment {
    // Validate environment
    NSArray *validEnvironments = @[@"dev", @"staging", @"production"];
    if (![validEnvironments containsObject:environment]) {
        [[CLXLogger shared] error:[NSString stringWithFormat:@"[CLXURLProvider] Invalid environment '%@'. Valid options: %@", 
              environment, validEnvironments]];
        return;
    }
    
    if ([environment isEqualToString:@"production"]) {
        // Clear override to use default production
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kInternalEnvironmentOverrideKey];
    } else {
        // Store the environment override
        [[NSUserDefaults standardUserDefaults] setObject:environment forKey:kInternalEnvironmentOverrideKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[CLXLogger shared] info:[NSString stringWithFormat:@"[CLXURLProvider] Environment set to: %@", environment]];
}

@end 

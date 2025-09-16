/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file URLProvider.m
 * @brief Implementation of URL provider functionality
 */

#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXEnvironmentConfig.h>

@implementation CLXURLProvider

+ (NSURL *)initApiUrl {
    CLXEnvironmentConfig *env = [CLXEnvironmentConfig shared];
    return [NSURL URLWithString:env.initializationEndpointURL];
}

+ (NSString *)auctionApiUrl {
    CLXEnvironmentConfig *env = [CLXEnvironmentConfig shared];
    return env.auctionEndpointURL;
}

+ (NSString *)metricsApiUrl {
    CLXEnvironmentConfig *env = [CLXEnvironmentConfig shared];
    return env.metricsEndpointURL;
}

@end 

/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file LiveInitService.m
 * @brief Implementation of live initialization service
 */

#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXSDKInitNetworkService.h>
#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/URLSession+CLX.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXLiveInitService ()
@property (nonatomic, strong) CLXSDKInitNetworkService *networkInitService;
@end

@implementation CLXLiveInitService

/**
 * @brief Initializes the live initialization service
 * @return An initialized instance of LiveInitService
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"InitService.m"];
        
        NSURL *initApiURL = [CLXURLProvider initApiUrl];
        NSURLSession *cloudxSession = [NSURLSession cloudxSessionWithIdentifier:@"init"];
        _networkInitService = [[CLXSDKInitNetworkService alloc] initWithBaseURL:initApiURL.absoluteString
                                                                 urlSession:cloudxSession];
        
        [self.logger info:@"✅ [LiveInitService] LiveInitService initialized successfully"];
    }
    return self;
}

/**
 * @brief Initializes the SDK with the provided app key
 * @param appKey The application key for SDK initialization
 * @param completion Completion handler called with the SDK configuration or error
 */
- (void)initSDKWithAppKey:(NSString *)appKey completion:(void (^)(CLXSDKConfigResponse * _Nullable, NSError * _Nullable))completion {
    [self.logger info:[NSString stringWithFormat:@"🚀 [LiveInitService] initSDKWithAppKey called - AppKey: %@", appKey]];
    
    if (!_networkInitService) {
        [self.logger error:@"❌ [LiveInitService] NetworkInitService is nil"];
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"LiveInitService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"NetworkInitService not initialized"}]);
        }
        return;
    }
    
    [_networkInitService initSDKWithAppKey:appKey completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [LiveInitService] NetworkInitService failed with error: %@", error]];
        } else {
            [self.logger info:@"✅ [LiveInitService] NetworkInitService succeeded"];
        }
        
        if (completion) {
            completion(config, error);
        }
    }];
}

@end 
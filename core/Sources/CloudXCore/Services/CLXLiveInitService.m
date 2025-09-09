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
        [self.logger debug:@"🔧 [LiveInitService] Initializing LiveInitService"];
        
        [self.logger debug:@"🔧 [LiveInitService] Getting init API URL from URLProvider"];
        NSURL *initApiURL = [CLXURLProvider initApiUrl];
        [self.logger debug:[NSString stringWithFormat:@"📊 [LiveInitService] Init API URL: %@", initApiURL.absoluteString]];
        
        [self.logger debug:@"🔧 [LiveInitService] Creating URLSession with CloudX identifier"];
        NSURLSession *cloudxSession = [NSURLSession cloudxSessionWithIdentifier:@"init"];
        [self.logger debug:[NSString stringWithFormat:@"📊 [LiveInitService] URLSession created: %@", cloudxSession]];
        
        [self.logger debug:@"🔧 [LiveInitService] Creating SDKInitNetworkService"];
        _networkInitService = [[CLXSDKInitNetworkService alloc] initWithBaseURL:initApiURL.absoluteString
                                                                 urlSession:cloudxSession];
        [self.logger info:[NSString stringWithFormat:@"✅ [LiveInitService] SDKInitNetworkService created successfully: %@", _networkInitService]];
        
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
    [self.logger info:@"🚀 [LiveInitService] initSDKWithAppKey called"];
    [self.logger debug:[NSString stringWithFormat:@"📊 [LiveInitService] AppKey: %@", appKey]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [LiveInitService] NetworkInitService: %@", _networkInitService]];
    
    if (!_networkInitService) {
        [self.logger error:@"❌ [LiveInitService] NetworkInitService is nil"];
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"LiveInitService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"NetworkInitService not initialized"}]);
        }
        return;
    }
    
    [self.logger debug:@"🔧 [LiveInitService] Calling networkInitService initSDKWithAppKey"];
    [_networkInitService initSDKWithAppKey:appKey completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        [self.logger debug:@"📥 [LiveInitService] NetworkInitService completion called"];
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [LiveInitService] NetworkInitService failed with error: %@", error]];
        } else {
            [self.logger info:@"✅ [LiveInitService] NetworkInitService succeeded"];
            if (config) {
                [self.logger debug:[NSString stringWithFormat:@"📊 [LiveInitService] Config received: %@", config]];
            } else {
                [self.logger debug:@"⚠️ [LiveInitService] Config is nil"];
            }
        }
        
        if (completion) {
            completion(config, error);
        }
    }];
}

@end 
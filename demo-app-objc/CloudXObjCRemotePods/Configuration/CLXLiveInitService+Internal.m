/*
 * ⚠️  INTERNAL TESTING ONLY - NOT FOR PUBLIC SDK USE  ⚠️
 *
 * This category extends CLXLiveInitService with internal testing methods
 * that are NOT part of the public SDK API. These methods are intended
 * solely for internal development, testing, and debugging purposes.
 *
 * DO NOT USE THESE METHODS IN PRODUCTION APPLICATIONS!
 * 
 * Public applications should use the standard CloudXCore initialization
 * methods provided in the main SDK interface.
 *
 * These internal methods may be removed, modified, or deprecated at any
 * time without notice and are not covered by SDK compatibility guarantees.
 */

#import "CLXLiveInitService+Internal.h"
#import <CloudXCore/CLXSDKInitNetworkService.h>
#import <CloudXCore/URLSession+CLX.h>

@implementation CLXLiveInitService (Internal)

- (void)initSDKWithAppKey:(NSString *)appKey 
            customInitURL:(NSString *)customInitURL 
               completion:(void (^)(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error))completion {
    
    [self.logger info:[NSString stringWithFormat:@"🚀 [LiveInitService+Internal] initSDKWithAppKey called with custom URL - AppKey: %@, URL: %@", appKey, customInitURL]];
    
    // Create a temporary network service with the custom URL
    NSURLSession *cloudxSession = [NSURLSession cloudxSessionWithIdentifier:@"init-internal"];
    CLXSDKInitNetworkService *customNetworkService = [[CLXSDKInitNetworkService alloc] 
        initWithBaseURL:customInitURL 
        urlSession:cloudxSession];
    
    if (!customNetworkService) {
        [self.logger error:@"❌ [LiveInitService+Internal] Failed to create custom NetworkInitService"];
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"LiveInitServiceInternal" 
                                               code:-1 
                                           userInfo:@{NSLocalizedDescriptionKey: @"Failed to create custom NetworkInitService"}]);
        }
        return;
    }
    
    [customNetworkService initSDKWithAppKey:appKey completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [LiveInitService+Internal] Custom NetworkInitService failed with error: %@", error]];
        } else {
            [self.logger info:@"✅ [LiveInitService+Internal] Custom NetworkInitService succeeded"];
        }
        
        if (completion) {
            completion(config, error);
        }
    }];
}

/**
 * @brief Initialize SDK with custom URL by temporarily overriding the internal network service
 * @param appKey The application key for SDK initialization
 * @param customInitURL Custom URL for SDK initialization endpoint
 * @param hashedUserId The hashed user ID for SDK initialization
 * @param completion Completion handler called with success status and error
 */
- (void)initSDKWithAppKey:(NSString *)appKey 
            customInitURL:(NSString *)customInitURL 
             hashedUserId:(NSString *)hashedUserId
               completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    [self initSDKWithAppKey:appKey customInitURL:customInitURL completion:^(CLXSDKConfigResponse * _Nullable config, NSError * _Nullable error) {
        // For demo purposes, we'll consider the config fetch as success and let the main SDK handle the rest
        if (completion) {
            completion(config != nil && error == nil, error);
        }
    }];
}

@end

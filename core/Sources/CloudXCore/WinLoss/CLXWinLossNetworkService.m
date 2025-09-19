/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXWinLossNetworkService.m
 * @brief Implementation of Win/Loss network service matching Android exactly
 */

#import <CloudXCore/CLXWinLossNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

@interface CLXWinLossNetworkService ()
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, assign) NSTimeInterval timeoutMillis;
@end

@implementation CLXWinLossNetworkService

- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession {
    self = [super init];
    if (self) {
        _baseNetworkService = [[CLXBaseNetworkService alloc] initWithBaseURL:baseURL urlSession:urlSession];
        _logger = [[CLXLogger alloc] initWithCategory:@"WinLossNetworkService"];
        _timeoutMillis = 10.0; // 10 second timeout matching Android
    }
    return self;
}

- (void)sendWithAppKey:(NSString *)appKey
           endpointUrl:(NSString *)endpointUrl
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    // Convert payload to JSON - matches Android's JSONObject(payload).toString()
    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload 
                                                       options:0 
                                                         error:&jsonError];
    
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"❌ [WinLossNetworkService] JSON serialization failed: %@", jsonError.localizedDescription]];
        if (completion) {
            completion(NO, jsonError);
        }
        return;
    }
    
    NSString *jsonBody = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // Debug logging matching Android's console output
    [self.logger debug:[NSString stringWithFormat:@"🔧 [WinLossNetworkService] Sending win/loss notification (%lu chars) to: %@", 
                       (unsigned long)jsonBody.length, endpointUrl]];
    [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossNetworkService] Win/Loss API Request Body: %@", jsonBody]];
    
    // Prepare headers matching Android's implementation
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    headers[@"Authorization"] = [NSString stringWithFormat:@"Bearer %@", appKey];
    headers[@"Content-Type"] = @"application/json";
    
    // Execute POST request using base class method signature
    [self.baseNetworkService executeRequestWithEndpoint:@"" // Full URL provided in endpointUrl
                                           urlParameters:nil
                                             requestBody:jsonData
                                                 headers:headers
                                              maxRetries:1
                                                   delay:1.0
                                              completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossNetworkService] Win/loss notification failed with exception: %@", error.localizedDescription]];
            [self.logger debug:@"📊 [WinLossNetworkService] Win/Loss API call exception"];
            
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        // Check HTTP status code (matches Android's response.status.value check)
        NSHTTPURLResponse *httpResponse = nil;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            httpResponse = (NSHTTPURLResponse *)response;
        }
        
        NSInteger statusCode = httpResponse ? httpResponse.statusCode : 200; // Default to success if no HTTP response
        
        [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossNetworkService] Win/Loss API Response Status: %ld", (long)statusCode]];
        
        // Match Android's success condition: code in 200..299
        if (statusCode >= 200 && statusCode < 300) {
            [self.logger debug:@"📊 [WinLossNetworkService] Win/loss notification sent successfully"];
            [self.logger debug:@"📊 [WinLossNetworkService] Win/Loss API call successful"];
            
            if (completion) {
                completion(YES, nil);
            }
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossNetworkService] Win/loss notification failed with HTTP status: %ld", (long)statusCode]];
            [self.logger debug:[NSString stringWithFormat:@"📊 [WinLossNetworkService] Win/Loss API call failed with status: %ld", (long)statusCode]];
            
            NSError *statusError = [CLXError errorWithCode:CLXErrorCodeServerError 
                                               description:[NSString stringWithFormat:@"HTTP %ld", (long)statusCode]];
            if (completion) {
                completion(NO, statusError);
            }
        }
    }];
}

@end

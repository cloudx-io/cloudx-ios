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
    CLXBaseNetworkService *baseService = [[CLXBaseNetworkService alloc] initWithBaseURL:baseURL urlSession:urlSession];
    return [self initWithBaseNetworkService:baseService];
}

- (instancetype)initWithBaseNetworkService:(CLXBaseNetworkService *)baseNetworkService {
    self = [super init];
    if (self) {
        _baseNetworkService = baseNetworkService;
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
    NSData *jsonData = nil;
    
    @try {
        jsonData = [NSJSONSerialization dataWithJSONObject:payload 
                                                   options:0 
                                                     error:&jsonError];
    } @catch (NSException *exception) {
        // Handle JSON serialization exceptions (e.g., unsupported data types)
        jsonError = [NSError errorWithDomain:@"CLXWinLossNetworkService" 
                                        code:1001 
                                    userInfo:@{
                                        NSLocalizedDescriptionKey: [NSString stringWithFormat:@"JSON serialization exception: %@", exception.reason],
                                        @"exception": exception
                                    }];
    }
    
    if (jsonError || !jsonData) {
        [self.logger error:[NSString stringWithFormat:@"JSON serialization failed: %@", jsonError.localizedDescription]];
        if (completion) {
            completion(NO, jsonError);
        }
        return;
    }
    
    NSString *jsonBody = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // Prepare headers matching Android's implementation
    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    headers[@"Authorization"] = [NSString stringWithFormat:@"Bearer %@", appKey];
    headers[@"Content-Type"] = @"application/json";
    
    // Execute POST request using base class method signature
    [self.baseNetworkService executeRequestWithEndpoint:@"" // Full URL provided in endpointUrl
                                           urlParameters:nil
                                             requestBody:jsonData
                                                 headers:headers
                                                 timeout:0  // Use session default (30s)
                                              maxRetries:3  // Match Android retry behavior
                                                   delay:1.0
                                              completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
        
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Win/loss notification failed: %@", error.localizedDescription]];
            
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
        
        // Match Android's success condition: code in 200..299
        if (statusCode >= 200 && statusCode < 300) {

            if (completion) {
                completion(YES, nil);
            }
        } else {
            [self.logger error:[NSString stringWithFormat:@"HTTP %ld", (long)statusCode]];

            CLXErrorCode errorCode = (statusCode >= 400 && statusCode < 500)
                ? CLXErrorCodeClientError
                : CLXErrorCodeServerError;

            NSError *statusError = [CLXError errorWithCode:errorCode
                                               description:[NSString stringWithFormat:@"HTTP %ld", (long)statusCode]];
            if (completion) {
                completion(NO, statusError);
            }
        }
    }];
}

@end

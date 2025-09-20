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
        [self.logger error:[NSString stringWithFormat:@"❌ [WinLossNetworkService] JSON serialization failed: %@", jsonError.localizedDescription]];
        if (completion) {
            completion(NO, jsonError);
        }
        return;
    }
    
    NSString *jsonBody = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // Enhanced debug logging - try to determine if this is a win or loss notification
    __block NSString *notificationType = @"UNKNOWN";
    NSError *parseError;
    id payloadData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&parseError];
    if (!parseError && [payloadData isKindOfClass:[NSDictionary class]]) {
        NSDictionary *payload = (NSDictionary *)payloadData;
        
        // Check for loss indicators first
        if (payload[@"loss_reason"] || payload[@"ortb_loss_code"]) {
            notificationType = @"LOSS";
        } else {
            // For win detection, look for any price-related field with positive value
            // Since field names are configurable, check common price field patterns
            NSArray *priceFieldPatterns = @[@"clearing_price", @"price", @"bid_price", @"auction_price", @"settlement_price"];
            for (NSString *priceField in priceFieldPatterns) {
                if (payload[priceField] && [payload[priceField] doubleValue] > 0) {
                    notificationType = @"WIN";
                    break;
                }
            }
            
            // If no price field found but no loss reason, likely still a win
            if ([notificationType isEqualToString:@"UNKNOWN"] && payload.count > 0) {
                // Check if any field contains a positive numeric value (likely a price)
                for (id value in payload.allValues) {
                    if ([value isKindOfClass:[NSNumber class]] && [value doubleValue] > 0) {
                        notificationType = @"WIN";
                        break;
                    } else if ([value isKindOfClass:[NSString class]]) {
                        double numericValue = [value doubleValue];
                        if (numericValue > 0) {
                            notificationType = @"WIN";
                            break;
                        }
                    }
                }
            }
        }
    }
    
    [self.logger debug:[NSString stringWithFormat:@"🔧 [WinLossNetworkService] Sending %@ notification (%lu chars) to: %@", 
                       notificationType, (unsigned long)jsonBody.length, endpointUrl]];
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
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossNetworkService] Win/loss notification failed: %@", error.localizedDescription]];
            
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
            [self.logger debug:[NSString stringWithFormat:@"✅ [WinLossNetworkService] %@ notification sent successfully", notificationType]];
            
            if (completion) {
                completion(YES, nil);
            }
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [WinLossNetworkService] Win/loss notification failed with HTTP status: %ld", (long)statusCode]];
            
            NSError *statusError = [CLXError errorWithCode:CLXErrorCodeServerError 
                                               description:[NSString stringWithFormat:@"HTTP %ld", (long)statusCode]];
            if (completion) {
                completion(NO, statusError);
            }
        }
    }];
}

@end

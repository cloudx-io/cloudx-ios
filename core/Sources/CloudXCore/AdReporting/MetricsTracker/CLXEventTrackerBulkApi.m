/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXEventTrackerBulkApi.h"
#import "CLXEventAM.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

@interface CLXEventTrackerBulkApiImpl ()
@property (nonatomic, assign) NSInteger timeoutMillis;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXEventTrackerBulkApiImpl

- (instancetype)initWithTimeoutMillis:(NSInteger)timeoutMillis {
    self = [super init];
    if (self) {
        _timeoutMillis = timeoutMillis > 0 ? timeoutMillis : 10000; // Default 10 seconds
        _logger = [[CLXLogger alloc] initWithCategory:@"EventTrackerBulkApi"];
    }
    return self;
}

- (void)sendToEndpoint:(NSString *)endpointUrl
                 items:(NSArray<CLXEventAM *> *)items
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    if (!endpointUrl || endpointUrl.length == 0) {
        [self.logger error:@"Endpoint URL is nil or empty"];
        if (completion) {
            completion(NO, [CLXError errorWithCode:CLXErrorCodeInternalError description:@"Endpoint URL is required"]);
        }
        return;
    }
    
    if (!items || items.count == 0) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    // Convert items to JSON array with URL encoding
    NSMutableArray *jsonArray = [NSMutableArray arrayWithCapacity:items.count];
    for (CLXEventAM *item in items) {
        NSDictionary *itemDict = [item toDictionary];
        
        // URL-encode campaignId and impression
        NSString *encodedCampaignId = [self _urlEncode:itemDict[@"campaignId"]];
        NSString *encodedImpression = [self _urlEncode:itemDict[@"impression"]];
        
        NSMutableDictionary *encodedDict = [itemDict mutableCopy];
        encodedDict[@"campaignId"] = encodedCampaignId ?: itemDict[@"campaignId"];
        encodedDict[@"impression"] = encodedImpression ?: itemDict[@"impression"];
        
        [jsonArray addObject:encodedDict];
    }
    
    // Wrap in "items" object
    NSDictionary *requestPayload = @{@"items": jsonArray};
    
    NSError *jsonError;
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:requestPayload options:NSJSONWritingPrettyPrinted error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"JSON serialization failed: %@", jsonError.localizedDescription]];
        if (completion) {
            completion(NO, jsonError);
        }
        return;
    }
    
    // Create request
    NSURL *url = [NSURL URLWithString:endpointUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = requestBody;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.timeoutInterval = self.timeoutMillis / 1000.0; // Convert to seconds
    
    // Execute request
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Network request failed: %@", error.localizedDescription]];
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        
        if (statusCode >= 200 && statusCode < 300) {
            if (completion) {
                completion(YES, nil);
            }
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"HTTP %ld", (long)statusCode];
            [self.logger error:[NSString stringWithFormat:@"HTTP error: %@", errorMessage]];
            
            // Log response body for debugging
            if (data) {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                [self.logger error:[NSString stringWithFormat:@"Server response: %@", responseString]];
            }
            
            NSError *httpError = [CLXError errorWithCode:CLXErrorCodeNetworkError description:errorMessage];
            if (completion) {
                completion(NO, httpError);
            }
        }
    }];
    
    [task resume];
}

- (NSString *)_urlEncode:(NSString *)string {
    if (!string) {
        return nil;
    }
    
    // Create character set that matches RFC 1738 (application/x-www-form-urlencoded)
    NSMutableCharacterSet *allowedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowedCharacters addCharactersInString:@"-_.*"];
    
    // Percent encode everything else (including = which becomes %3D)
    NSString *encoded = [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    
    return encoded;
}

@end

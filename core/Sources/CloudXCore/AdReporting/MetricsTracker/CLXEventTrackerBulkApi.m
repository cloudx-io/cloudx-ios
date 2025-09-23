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
        [self.logger error:@"❌ [EventTrackerBulkApi] Endpoint URL is nil or empty"];
        if (completion) {
            completion(NO, [CLXError errorWithCode:CLXErrorCodeInvalidRequest description:@"Endpoint URL is required"]);
        }
        return;
    }
    
    if (!items || items.count == 0) {
        [self.logger debug:@"📊 [EventTrackerBulkApi] No items to send"];
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"📊 [EventTrackerBulkApi] Sending %lu metrics events to %@", 
                       (unsigned long)items.count, endpointUrl]];
    
    // Convert items to JSON array
    NSMutableArray *jsonArray = [NSMutableArray arrayWithCapacity:items.count];
    for (CLXEventAM *item in items) {
        [jsonArray addObject:[item toDictionary]];
    }
    
    NSError *jsonError;
    NSData *requestBody = [NSJSONSerialization dataWithJSONObject:jsonArray options:0 error:&jsonError];
    if (jsonError) {
        [self.logger error:[NSString stringWithFormat:@"❌ [EventTrackerBulkApi] JSON serialization failed: %@", jsonError.localizedDescription]];
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
    
    // Log request details
    [self.logger debug:[NSString stringWithFormat:@"📊 [EventTrackerBulkApi] Request body size: %lu bytes", (unsigned long)requestBody.length]];
    
    // Execute request
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"❌ [EventTrackerBulkApi] Network request failed: %@", error.localizedDescription]];
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        
        if (statusCode >= 200 && statusCode < 300) {
            [self.logger debug:[NSString stringWithFormat:@"✅ [EventTrackerBulkApi] Successfully sent %lu metrics events (status: %ld)", 
                               (unsigned long)items.count, (long)statusCode]];
            if (completion) {
                completion(YES, nil);
            }
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"HTTP %ld", (long)statusCode];
            [self.logger error:[NSString stringWithFormat:@"❌ [EventTrackerBulkApi] HTTP error: %@", errorMessage]];
            
            NSError *httpError = [CLXError errorWithCode:CLXErrorCodeNetworkError description:errorMessage];
            if (completion) {
                completion(NO, httpError);
            }
        }
    }];
    
    [task resume];
}

@end

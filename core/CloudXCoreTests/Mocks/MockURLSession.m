/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "MockURLSession.h"

#pragma mark - MockURLSessionResponse

@implementation MockURLSessionResponse

+ (instancetype)responseWithStatusCode:(NSInteger)statusCode data:(nullable NSData *)data {
    return [self responseWithStatusCode:statusCode data:data headers:nil];
}

+ (instancetype)responseWithStatusCode:(NSInteger)statusCode data:(nullable NSData *)data headers:(nullable NSDictionary *)headers {
    MockURLSessionResponse *response = [[MockURLSessionResponse alloc] init];
    response.statusCode = statusCode;
    response.data = data;
    response.headers = headers;
    response.error = nil;
    return response;
}

+ (instancetype)responseWithError:(NSError *)error {
    MockURLSessionResponse *response = [[MockURLSessionResponse alloc] init];
    response.statusCode = 0;
    response.data = nil;
    response.headers = nil;
    response.error = error;
    return response;
}

@end

#pragma mark - MockURLSessionDataTask

@implementation MockURLSessionDataTask

- (instancetype)init {
    // Note: We cannot call [super init] on NSURLSessionDataTask as it requires
    // a valid session. We create a minimal mock that tracks resume/cancel calls.
    _resumeCalled = NO;
    _cancelCalled = NO;
    return self;
}

- (void)resume {
    self.resumeCalled = YES;
    // No-op: completion handler already executed synchronously
}

- (void)cancel {
    self.cancelCalled = YES;
    // No-op: task already "completed"
}

@end

#pragma mark - MockURLSession

@interface MockURLSession ()
@property (nonatomic, strong, readwrite) NSMutableArray<MockURLSessionResponse *> *queuedResponses;
@property (nonatomic, assign, readwrite) NSInteger callCount;
@property (nonatomic, strong, readwrite) NSMutableArray<NSURLRequest *> *capturedRequests;
@end

@implementation MockURLSession

- (instancetype)init {
    // Note: NSURLSession normally requires configuration, but we're mocking
    self = [super init];
    if (self) {
        _queuedResponses = [NSMutableArray array];
        _callCount = 0;
        _capturedRequests = [NSMutableArray array];
    }
    return self;
}

#pragma mark - NSURLSession Override

/**
 * CRITICAL: This method executes the completion handler SYNCHRONOUSLY.
 * This is the key to eliminating timing-related test flakiness.
 *
 * In real NSURLSession, completion runs on a background queue after network I/O.
 * In MockURLSession, completion runs immediately on the calling thread.
 */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler {
    
    // Track the request
    self.callCount++;
    [self.capturedRequests addObject:[request copy]];
    
    // Dequeue next response (or use default if empty)
    MockURLSessionResponse *response = nil;
    if (self.queuedResponses.count > 0) {
        response = self.queuedResponses.firstObject;
        [self.queuedResponses removeObjectAtIndex:0];
    }
    
    // Create the mock data task
    MockURLSessionDataTask *task = [[MockURLSessionDataTask alloc] init];
    
    // SYNCHRONOUS EXECUTION - no dispatch_async, no delays!
    if (completionHandler) {
        if (response.error) {
            // Error response (simulates network failure)
            completionHandler(nil, nil, response.error);
        } else if (response) {
            // Success response
            NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] 
                initWithURL:request.URL ?: [NSURL URLWithString:@"https://mock.test"]
                statusCode:response.statusCode
                HTTPVersion:@"HTTP/1.1"
                headerFields:response.headers];
            completionHandler(response.data, httpResponse, nil);
        } else {
            // No response queued - return empty 200 by default
            NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] 
                initWithURL:request.URL ?: [NSURL URLWithString:@"https://mock.test"]
                statusCode:200
                HTTPVersion:@"HTTP/1.1"
                headerFields:nil];
            completionHandler(nil, httpResponse, nil);
        }
    }
    
    return task;
}

#pragma mark - Enqueueing Responses

- (void)enqueueResponseWithStatusCode:(NSInteger)statusCode data:(nullable NSData *)data {
    [self enqueueResponseWithStatusCode:statusCode data:data headers:nil];
}

- (void)enqueueResponseWithStatusCode:(NSInteger)statusCode 
                                 data:(nullable NSData *)data 
                              headers:(nullable NSDictionary<NSString *, NSString *> *)headers {
    MockURLSessionResponse *response = [MockURLSessionResponse responseWithStatusCode:statusCode data:data headers:headers];
    [self.queuedResponses addObject:response];
}

- (void)enqueueError:(NSError *)error {
    MockURLSessionResponse *response = [MockURLSessionResponse responseWithError:error];
    [self.queuedResponses addObject:response];
}

- (void)enqueueResponse:(MockURLSessionResponse *)response {
    [self.queuedResponses addObject:response];
}

#pragma mark - Test Utilities

- (void)reset {
    [self.queuedResponses removeAllObjects];
    [self.capturedRequests removeAllObjects];
    self.callCount = 0;
}

- (nullable NSURLRequest *)lastRequest {
    return self.capturedRequests.lastObject;
}

@end

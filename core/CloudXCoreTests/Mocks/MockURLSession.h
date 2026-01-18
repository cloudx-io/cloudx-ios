/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file MockURLSession.h
 * @brief Mock NSURLSession for unit testing network behavior
 *
 * CRITICAL DESIGN: SYNCHRONOUS execution of completion handlers.
 * This eliminates all timing-related test flakiness.
 *
 * Usage:
 *   MockURLSession *mock = [[MockURLSession alloc] init];
 *   [mock enqueueResponseWithStatusCode:200 data:jsonData headers:nil];
 *   [mock enqueueResponseWithStatusCode:500 data:nil headers:nil]; // For retry tests
 *   
 *   // Inject into service
 *   CLXBaseNetworkService *service = [[CLXBaseNetworkService alloc] initWithBaseURL:@"https://test.com" urlSession:mock];
 *
 * ZERO real network calls - all responses are queued and returned synchronously.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - MockURLSessionResponse

/**
 * Represents a single HTTP response to be returned by MockURLSession
 */
@interface MockURLSessionResponse : NSObject

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, strong, nullable) NSData *data;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *headers;
@property (nonatomic, strong, nullable) NSError *error;

/// Convenience factory for success response
+ (instancetype)responseWithStatusCode:(NSInteger)statusCode data:(nullable NSData *)data;

/// Convenience factory for success response with headers
+ (instancetype)responseWithStatusCode:(NSInteger)statusCode data:(nullable NSData *)data headers:(nullable NSDictionary *)headers;

/// Convenience factory for error response
+ (instancetype)responseWithError:(NSError *)error;

@end

#pragma mark - MockURLSessionDataTask

/**
 * No-op data task returned by MockURLSession.
 * Since completion handlers execute synchronously, the task is already "complete" when returned.
 */
@interface MockURLSessionDataTask : NSURLSessionDataTask

@property (nonatomic, assign) BOOL resumeCalled;
@property (nonatomic, assign) BOOL cancelCalled;

@end

#pragma mark - MockURLSession

/**
 * Mock NSURLSession that returns queued responses SYNCHRONOUSLY.
 * No real network calls, no timing issues, no flaky tests.
 */
@interface MockURLSession : NSURLSession

/// Queued responses - first response is dequeued and returned for each request
@property (nonatomic, strong, readonly) NSMutableArray<MockURLSessionResponse *> *queuedResponses;

/// Number of times a request was made
@property (nonatomic, assign, readonly) NSInteger callCount;

/// All requests that were made (for verification)
@property (nonatomic, strong, readonly) NSMutableArray<NSURLRequest *> *capturedRequests;

#pragma mark - Enqueueing Responses

/// Enqueue a success response with status code and optional data
- (void)enqueueResponseWithStatusCode:(NSInteger)statusCode data:(nullable NSData *)data;

/// Enqueue a success response with status code, data, and headers
- (void)enqueueResponseWithStatusCode:(NSInteger)statusCode 
                                 data:(nullable NSData *)data 
                              headers:(nullable NSDictionary<NSString *, NSString *> *)headers;

/// Enqueue an error response (simulates network failure)
- (void)enqueueError:(NSError *)error;

/// Enqueue a pre-built response object
- (void)enqueueResponse:(MockURLSessionResponse *)response;

#pragma mark - Test Utilities

/// Clear all queued responses and reset call count
- (void)reset;

/// Get the last captured request (convenience)
- (nullable NSURLRequest *)lastRequest;

@end

NS_ASSUME_NONNULL_END

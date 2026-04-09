/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file BaseNetworkService.h
 * @brief Base class for network services providing common networking functionality
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol CLXScheduler
 * @brief Protocol for scheduling delayed execution
 * @discussion Allows dependency injection of scheduling behavior for testability.
 */
@protocol CLXScheduler <NSObject>
- (void)scheduleAfterDelay:(NSTimeInterval)delay
                   onQueue:(dispatch_queue_t)queue
                     block:(dispatch_block_t)block;
@end

/**
 * @class CLXDispatchScheduler
 * @brief Production scheduler using real dispatch_after
 */
@interface CLXDispatchScheduler : NSObject <CLXScheduler>
+ (instancetype)sharedInstance;
@end

/**
 * @class CLXSynchronousScheduler  
 * @brief Test scheduler that executes blocks immediately
 */
@interface CLXSynchronousScheduler : NSObject <CLXScheduler>
@end

/**
 * @class BaseNetworkService
 * @brief Base class for all network services in the SDK
 * @discussion This class provides common networking functionality including request execution,
 * retry logic, and error handling. All network services should inherit from this class.
 */
@interface CLXBaseNetworkService : NSObject

/** The base URL for all network requests */
@property (nonatomic, copy) NSString *baseURL;

/** The URL session used for network requests */
@property (nonatomic, strong) NSURLSession *urlSession;

/** The scheduler used for retry delays (injectable for testing) */
@property (nonatomic, strong) id<CLXScheduler> scheduler;

/**
 * @brief Initializes the network service with base URL and session
 * @param baseURL The base URL for API requests
 * @param urlSession The URL session to use for network requests
 * @return An initialized instance of BaseNetworkService
 * @note Uses CLXDispatchScheduler by default for production retry delays
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession;

/**
 * @brief Initializes the network service with base URL, session, and custom scheduler
 * @param baseURL The base URL for API requests
 * @param urlSession The URL session to use for network requests
 * @param scheduler The scheduler to use for retry delays (use CLXSynchronousScheduler for tests)
 * @return An initialized instance of BaseNetworkService
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL 
                     urlSession:(NSURLSession *)urlSession
                      scheduler:(id<CLXScheduler>)scheduler;

/**
 * @brief Returns the headers required for API requests
 * @return Dictionary containing the required headers
 */
- (NSDictionary *)headers;

/**
 * @brief Executes a network request with the given parameters
 * @param endpoint The API endpoint to call
 * @param urlParameters Dictionary of URL parameters
 * @param requestBody The request body data
 * @param headers Dictionary of request headers
 * @param timeout Request timeout in seconds (0 = use session default of 30s)
 * @param maxRetries Maximum number of retry attempts
 * @param delay Delay between retry attempts in seconds
 * @param completion Completion handler called with the response or error
 */
- (void)executeRequestWithEndpoint:(NSString *)endpoint
                    urlParameters:(nullable NSDictionary *)urlParameters
                     requestBody:(nullable NSData *)requestBody
                         headers:(nullable NSDictionary *)headers
                         timeout:(NSTimeInterval)timeout
                      maxRetries:(NSInteger)maxRetries
                          delay:(NSTimeInterval)delay
                     completion:(void (^)(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled, NSHTTPURLResponse * _Nullable httpResponse))completion;

@end

NS_ASSUME_NONNULL_END 

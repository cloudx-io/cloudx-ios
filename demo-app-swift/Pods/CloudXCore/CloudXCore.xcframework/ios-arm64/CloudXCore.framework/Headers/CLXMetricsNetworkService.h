//
//  MetricsNetworkService.h
//  CloudXCore
//
//  Created by Migration Tool.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXAppSessionModel.h>
#import <CloudXCore/CLXSessionMetricSpend.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Network error enumeration for metrics network service
 */
typedef NS_ENUM(NSInteger, MetricsNetworkError) {
    MetricsNetworkErrorInvalidRequest
};

/**
 * @brief Metric structure for metrics network service request
 */
@interface CLXMetricsNetworkServiceRequestSessionMetric : NSObject

@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, strong, nullable) NSNumber *value;
@property (nonatomic, strong, nullable) NSDate *timestamp;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSNumber *> *meta;

- (instancetype)initWithMetric:(CLXSessionMetricSpend *)metric;
- (instancetype)initWithType:(NSString *)type meta:(NSDictionary<NSString *, NSNumber *> *)meta;

@end

/**
 * @brief Session structure for metrics network service request
 */
@interface CLXMetricsNetworkServiceRequestSession : NSObject

@property (nonatomic, copy) NSString *ID;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, strong) NSArray<CLXMetricsNetworkServiceRequestSessionMetric *> *metrics;

- (instancetype)initWithID:(NSString *)ID
                  duration:(NSInteger)duration
                                        metrics:(NSArray<CLXMetricsNetworkServiceRequestSessionMetric *> *)metrics;

@end

/**
 * @brief Request structure for metrics network service
 */
@interface CLXMetricsNetworkServiceRequest : NSObject

@property (nonatomic, strong) CLXMetricsNetworkServiceRequestSession *session;

- (instancetype)initWithSession:(CLXMetricsNetworkServiceRequestSession *)session;

@end

/**
 * @brief Network service for tracking metrics
 * 
 * This service is responsible for sending session metrics to the server.
 * It handles the conversion of AppSessionModel to the appropriate request format
 * and sends the data via HTTP POST requests.
 */
@interface CLXMetricsNetworkService : CLXBaseNetworkService

/**
 * @brief Tracks the end of a session by sending metrics to the server
 * 
 * This method converts the AppSessionModel to the appropriate request format
 * and sends it to the server. It handles both regular metrics and performance metrics.
 * 
 * @param session The AppSessionModel containing the session data to track
 * @param completion Completion block called when the operation finishes
 */
- (void)trackEndSessionWithSession:(CLXAppSessionModel *)session
                       completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/**
 * @brief Tracks the end of a session by sending metrics to the server (async version)
 * 
 * This method converts the AppSessionModel to the appropriate request format
 * and sends it to the server. It handles both regular metrics and performance metrics.
 * 
 * @param session The CLXAppSessionModel containing the session data to track
 */
- (void)trackEndSessionWithSession:(CLXAppSessionModel *)session;

@end

NS_ASSUME_NONNULL_END 
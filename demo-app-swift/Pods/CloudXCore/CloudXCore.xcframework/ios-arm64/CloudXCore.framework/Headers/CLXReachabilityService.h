/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file ReachabilityService.h
 * @brief Reachability service implementation
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ReachabilityType) {
    ReachabilityTypeUnknown = 0,
    ReachabilityTypeWWAN2G = 1,
    ReachabilityTypeWWAN3G = 2,
    ReachabilityTypeWWAN4G = 3,
    ReachabilityTypeWiFi = 4,
    ReachabilityTypeNone = 5
};

/**
 * Service for monitoring network reachability
 */
@interface CLXReachabilityService : NSObject

/**
 * Shared singleton instance
 * @return Shared reachability service instance
 */
+ (instancetype)shared;

/**
 * Current reachability type
 * @return Current network connection type
 */
@property (nonatomic, assign, readonly) ReachabilityType currentReachabilityType;

/**
 * Initialize a new reachability service
 * @return Initialized reachability service
 */
- (instancetype)init;

/**
 * Get current connection status
 * @return Current connection status
 */
- (NSInteger)connectionStatus;

@end

NS_ASSUME_NONNULL_END 
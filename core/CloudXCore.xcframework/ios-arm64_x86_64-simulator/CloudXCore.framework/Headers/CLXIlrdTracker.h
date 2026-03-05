/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXIlrdService;
@protocol CLXIlrdNetworkServiceProtocol;

/**
 * Coordinates ILRD event collection and sending.
 * Subscribes to an IlrdService for events and forwards them
 * to the backend via the network service on a serial background queue.
 */
@interface CLXIlrdTracker : NSObject

/**
 * Full initializer with injectable network service (for testing).
 */
- (instancetype)initWithAppKey:(NSString *)appKey
                   endpointUrl:(NSString *)endpointUrl
                   ilrdService:(CLXIlrdService *)ilrdService
                networkService:(id<CLXIlrdNetworkServiceProtocol>)networkService;

/**
 * Convenience initializer that creates a default network service.
 */
- (instancetype)initWithAppKey:(NSString *)appKey
                   endpointUrl:(NSString *)endpointUrl
                   ilrdService:(CLXIlrdService *)ilrdService;

/**
 * Start listening for ILRD events and sending them to the backend.
 */
- (void)start;

/**
 * Stop listening and clean up.
 */
- (void)stop;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXIlrdService;
@protocol CLXIlrdNetworkServiceProtocol;

/**
 * Collects ILRD impression events from CLXIlrdService, enriches them with SDK identity
 * and CX auction data, then sends them to the backend via CLXIlrdNetworkService.
 *
 * Observes CLXAuctionResultNotification to track no-fill auctions per ad format.
 * When an ILRD impression arrives for a format that had a no-fill, the event is
 * enriched with cxAuctionId and cxAdUnitId (one-shot, then consumed).
 */
@interface CLXIlrdTracker : NSObject

- (instancetype)initWithAppKey:(NSString *)appKey
                     accountId:(NSString *)accountId
                     sessionId:(NSString *)sessionId
                    sdkVersion:(NSString *)sdkVersion
                   endpointUrl:(NSString *)endpointUrl
                   ilrdService:(CLXIlrdService *)ilrdService
                networkService:(id<CLXIlrdNetworkServiceProtocol>)networkService;

- (void)start;
- (void)stop;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

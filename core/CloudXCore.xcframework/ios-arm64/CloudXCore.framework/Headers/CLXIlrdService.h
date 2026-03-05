/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXIlrdProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Aggregates multiple ILRD providers and forwards their events
 * through a single callback.
 */
@interface CLXIlrdService : NSObject

/**
 * Initialize with a dictionary of providers keyed by platform.
 */
- (instancetype)initWithProviders:(NSDictionary<NSNumber *, id<CLXIlrdProvider>> *)providers;

/**
 * Subscribe all providers. Returns YES if at least one provider succeeded.
 * Sets the event callback on each successful provider.
 */
- (BOOL)subscribeWithError:(NSError **)outError;

/**
 * Unsubscribe all providers.
 */
- (void)unsubscribe;

/**
 * Set the callback to receive aggregated ILRD events from all providers.
 */
- (void)setEventCallback:(nullable CLXIlrdEventCallback)callback;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

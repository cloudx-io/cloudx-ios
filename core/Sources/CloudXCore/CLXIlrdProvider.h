/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Platforms that can provide ILRD (Impression Level Revenue Data) events.
 */
typedef NS_ENUM(NSInteger, CLXIlrdPlatform) {
    CLXIlrdPlatformAl = 0,
};

/**
 * Callback block invoked when an ILRD event is received.
 * The event dictionary contains revenue data fields ready for JSON serialization.
 */
typedef void (^CLXIlrdEventCallback)(NSDictionary<NSString *, id> *event);

/**
 * Protocol for ILRD event providers.
 * Each provider subscribes to a specific ad platform's revenue events
 * and forwards them via the event callback.
 */
@protocol CLXIlrdProvider <NSObject>

/**
 * The platform this provider handles.
 */
@property (nonatomic, readonly) CLXIlrdPlatform platform;

/**
 * Subscribe to ILRD events from the platform.
 * Returns YES on success, NO on failure (error details in outError).
 */
- (BOOL)subscribeWithError:(NSError **)outError;

/**
 * Unsubscribe from ILRD events.
 * Returns YES on success, NO on failure (error details in outError).
 */
- (BOOL)unsubscribeWithError:(NSError **)outError;

/**
 * Set the callback to receive ILRD events.
 * Pass nil to clear the callback.
 */
- (void)setEventCallback:(nullable CLXIlrdEventCallback)callback;

@end

NS_ASSUME_NONNULL_END

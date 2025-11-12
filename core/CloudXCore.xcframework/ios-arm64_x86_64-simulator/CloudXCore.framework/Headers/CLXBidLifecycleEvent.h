/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidLifecycleEvent.h
 * @brief Defines the lifecycle events for bid tracking (BID_RECEIVED, LOAD_SUCCESS, RENDER_SUCCESS, LOSS)
 *
 * Each lifecycle event has an associated notification type and URL type (lurl, nurl, burl)
 * that determines which URL to fire and what payload to send.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Bid lifecycle event types (matches Android implementation)
 */
typedef NS_ENUM(NSInteger, CLXBidLifecycleEventType) {
    /**
     * Bid successfully loaded
     * notificationType: "loadSuccess"
     * urlType: "nurl" (notification URL)
     */
    CLXBidLifecycleEventTypeLoadSuccess,
    
    /**
     * Bid successfully rendered (impression tracked)
     * notificationType: "renderSuccess"
     * urlType: "burl" (billing URL)
     */
    CLXBidLifecycleEventTypeRenderSuccess,
    
    /**
     * Bid lost in auction or failed to load
     * notificationType: "loss"
     * urlType: "lurl" (loss URL)
     */
    CLXBidLifecycleEventTypeLoss
};

/**
 * Represents a bid lifecycle event with its associated notification type and URL type
 */
@interface CLXBidLifecycleEvent : NSObject

/**
 * The type of lifecycle event
 */
@property (nonatomic, assign, readonly) CLXBidLifecycleEventType type;

/**
 * The notification type string (e.g., "loadSuccess", "renderSuccess", "loss", or "" for BID_RECEIVED)
 */
@property (nonatomic, copy, readonly) NSString *notificationType;

/**
 * The URL type to use (e.g., "lurl", "nurl", "burl")
 */
@property (nonatomic, copy, readonly) NSString *urlType;

/**
 * Factory method for LOAD_SUCCESS event
 */
+ (instancetype)loadSuccessEvent;

/**
 * Factory method for RENDER_SUCCESS event
 */
+ (instancetype)renderSuccessEvent;

/**
 * Factory method for LOSS event
 */
+ (instancetype)lossEvent;

/**
 * Designated initializer
 */
- (instancetype)initWithType:(CLXBidLifecycleEventType)type
              notificationType:(NSString *)notificationType
                       urlType:(NSString *)urlType NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

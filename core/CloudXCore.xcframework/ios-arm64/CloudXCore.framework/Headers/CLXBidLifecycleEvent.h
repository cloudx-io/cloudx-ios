/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidLifecycleEvent.h
 * @brief Defines the lifecycle events for bid tracking (LOAD_SUCCESS, RENDER_SUCCESS, LOSS, REWARD)
 *
 * Each lifecycle event has an associated notification type and URL type (lurl, nurl, burl)
 * that determines which URL to fire and what payload to send.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Notification Type Constants

/** Notification type for successful bid load */
extern NSString * const CLXNotificationTypeLoadSuccess;
/** Notification type for successful render/impression */
extern NSString * const CLXNotificationTypeRenderSuccess;
/** Notification type for bid loss */
extern NSString * const CLXNotificationTypeLoss;
/** Notification type for rewarded ad completion */
extern NSString * const CLXNotificationTypeRewardEarned;

#pragma mark - URL Type Constants

/** Notification URL - fired on load success */
extern NSString * const CLXURLTypeNurl;
/** Billing URL - fired on render success and reward */
extern NSString * const CLXURLTypeBurl;
/** Loss URL - fired on bid loss */
extern NSString * const CLXURLTypeLurl;

#pragma mark - Event Types

/**
 * Bid lifecycle event types (matches Android implementation)
 */
typedef NS_ENUM(NSInteger, CLXBidLifecycleEventType) {
    /**
     * Bid successfully loaded
     * notificationType: CLXNotificationTypeLoadSuccess
     * urlType: CLXURLTypeNurl
     */
    CLXBidLifecycleEventTypeLoadSuccess,
    
    /**
     * Bid successfully rendered (impression tracked)
     * notificationType: CLXNotificationTypeRenderSuccess
     * urlType: CLXURLTypeBurl
     */
    CLXBidLifecycleEventTypeRenderSuccess,
    
    /**
     * Bid lost in auction or failed to load
     * notificationType: CLXNotificationTypeLoss
     * urlType: CLXURLTypeLurl
     */
    CLXBidLifecycleEventTypeLoss,
    
    /**
     * User completed rewarded ad and earned reward
     * notificationType: CLXNotificationTypeRewardEarned
     * urlType: CLXURLTypeBurl
     */
    CLXBidLifecycleEventTypeReward
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
 * Factory method for REWARD event (user completed rewarded ad)
 */
+ (instancetype)rewardEvent;

/**
 * Designated initializer
 */
- (instancetype)initWithType:(CLXBidLifecycleEventType)type
              notificationType:(NSString *)notificationType
                       urlType:(NSString *)urlType NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

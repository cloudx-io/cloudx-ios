/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidLifecycleEvent.m
 * @brief Implementation of bid lifecycle event types
 */

#import "CLXBidLifecycleEvent.h"

#pragma mark - Notification Type Constants

NSString * const CLXNotificationTypeLoadSuccess = @"loadSuccess";
NSString * const CLXNotificationTypeRenderSuccess = @"renderSuccess";
NSString * const CLXNotificationTypeLoss = @"loss";
NSString * const CLXNotificationTypeRewardEarned = @"rewardEarned";

#pragma mark - URL Type Constants

NSString * const CLXURLTypeNurl = @"nurl";
NSString * const CLXURLTypeBurl = @"burl";
NSString * const CLXURLTypeLurl = @"lurl";

#pragma mark - Implementation

@implementation CLXBidLifecycleEvent

+ (instancetype)loadSuccessEvent {
    return [[self alloc] initWithType:CLXBidLifecycleEventTypeLoadSuccess
                     notificationType:CLXNotificationTypeLoadSuccess
                              urlType:CLXURLTypeNurl];
}

+ (instancetype)renderSuccessEvent {
    return [[self alloc] initWithType:CLXBidLifecycleEventTypeRenderSuccess
                     notificationType:CLXNotificationTypeRenderSuccess
                              urlType:CLXURLTypeBurl];
}

+ (instancetype)lossEvent {
    return [[self alloc] initWithType:CLXBidLifecycleEventTypeLoss
                     notificationType:CLXNotificationTypeLoss
                              urlType:CLXURLTypeLurl];
}

+ (instancetype)rewardEvent {
    return [[self alloc] initWithType:CLXBidLifecycleEventTypeReward
                     notificationType:CLXNotificationTypeRewardEarned
                              urlType:CLXURLTypeBurl];
}

- (instancetype)initWithType:(CLXBidLifecycleEventType)type
              notificationType:(NSString *)notificationType
                       urlType:(NSString *)urlType {
    self = [super init];
    if (self) {
        _type = type;
        _notificationType = [notificationType copy];
        _urlType = [urlType copy];
    }
    return self;
}

@end

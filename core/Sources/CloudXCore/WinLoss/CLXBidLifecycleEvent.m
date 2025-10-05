/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidLifecycleEvent.m
 * @brief Implementation of bid lifecycle event types
 */

#import "CLXBidLifecycleEvent.h"

@implementation CLXBidLifecycleEvent

+ (instancetype)loadSuccessEvent {
    return [[self alloc] initWithType:CLXBidLifecycleEventTypeLoadSuccess
                     notificationType:@"loadSuccess"
                              urlType:@"nurl"];
}

+ (instancetype)renderSuccessEvent {
    return [[self alloc] initWithType:CLXBidLifecycleEventTypeRenderSuccess
                     notificationType:@"renderSuccess"
                              urlType:@"burl"];
}

+ (instancetype)lossEvent {
    return [[self alloc] initWithType:CLXBidLifecycleEventTypeLoss
                     notificationType:@"loss"
                              urlType:@"lurl"];
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

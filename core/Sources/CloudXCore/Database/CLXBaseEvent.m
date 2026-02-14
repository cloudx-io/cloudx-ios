/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXBaseEvent.h"

@implementation CLXBaseEvent

@synthesize eventId = _eventId;

#pragma mark - Initialization

- (instancetype)initWithEventId:(NSString *)eventId sessionId:(NSString *)sessionId {
    if (self = [super init]) {
        _eventId = [eventId copy];
        _sessionId = [sessionId copy];
        _createdAt = [[NSDate date] timeIntervalSince1970];
    }
    return self;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"CLXBaseEvent is an abstract class. Use initWithEventId:sessionId:"
                                 userInfo:nil];
}


@end

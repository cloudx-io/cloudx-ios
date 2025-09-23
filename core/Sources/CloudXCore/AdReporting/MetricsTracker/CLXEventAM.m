/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXEventAM.h"

@implementation CLXEventAM

- (instancetype)initWithImpression:(NSString *)impression
                         campaignId:(NSString *)campaignId
                         eventValue:(NSString *)eventValue
                          eventName:(NSString *)eventName
                               type:(NSString *)type {
    self = [super init];
    if (self) {
        _impression = [impression copy];
        _campaignId = [campaignId copy];
        _eventValue = [eventValue copy];
        _eventName = [eventName copy];
        _type = [type copy];
    }
    return self;
}

- (NSDictionary *)toDictionary {
    return @{
        @"impression": self.impression,
        @"campaignId": self.campaignId,
        @"eventValue": self.eventValue,
        @"eventName": self.eventName,
        @"type": self.type
    };
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CLXEventAM{impression=%@, campaignId=%@, eventName=%@, type=%@}",
            [self.impression substringToIndex:MIN(10, self.impression.length)], // Only show first 10 chars of encrypted data
            self.campaignId, self.eventName, self.type];
}

@end

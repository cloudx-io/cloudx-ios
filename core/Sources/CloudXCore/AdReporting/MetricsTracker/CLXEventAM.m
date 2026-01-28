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

/**
 * Convert to dictionary for JSON serialization.
 * CRITICAL: Must match Android's EventBulkRequestToJson format exactly.
 * Android sends: eventName, campaignId, type, impression (4 fields)
 * Android does NOT send eventValue - we exclude it here for parity.
 */
- (NSDictionary *)toDictionary {
    return @{
        @"eventName": self.eventName ?: @"",
        @"campaignId": [self urlEncodeBase64:self.campaignId],
        @"type": self.type ?: @"",
        @"impression": [self urlEncodeBase64:self.impression]
        // NOTE: eventValue intentionally excluded to match Android JSON format
    };
}

/**
 * URL-encode a Base64 string for backend compatibility.
 * The backend (cloudx-tracker) calls URLDecoder.decode() before Base64 decoding.
 * Base64 uses only: A-Z, a-z, 0-9, +, /, = (padding)
 * Only +, /, = need encoding as they have special meaning in URLs.
 */
- (NSString *)urlEncodeBase64:(NSString *)base64String {
    if (!base64String) return @"";
    return [[[base64String
        stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"]
        stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"]
        stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
}

- (NSString *)description {
    // Nil-safe: substringToIndex: on nil throws NSRangeException
    NSString *impressionPreview = self.impression
        ? [self.impression substringToIndex:MIN(10, self.impression.length)]
        : @"(nil)";
    return [NSString stringWithFormat:@"CLXEventAM{impression=%@, campaignId=%@, eventName=%@, type=%@}",
            impressionPreview, self.campaignId, self.eventName, self.type];
}

@end

/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXEventType.h"

#pragma mark - Event Type Path Segments

// Must match Android EventType.pathSegment values exactly
NSString * const CLXEventTypePathSDKInit      = @"sdkinitenc";
NSString * const CLXEventTypePathClick        = @"clickenc";
NSString * const CLXEventTypePathImpression   = @"sdkimpenc";
NSString * const CLXEventTypePathBidRequest   = @"bidreqenc";
NSString * const CLXEventTypePathSDKError     = @"sdkerrorenc";
NSString * const CLXEventTypePathSDKCrash     = @"sdkcrashenc";
NSString * const CLXEventTypePathSDKMetrics   = @"sdkmetricenc";

#pragma mark - Event Type Codes

// Must match Android EventType.code values exactly
NSString * const CLXEventTypeCodeSDKInit      = @"sdkinit";
NSString * const CLXEventTypeCodeClick        = @"click";
NSString * const CLXEventTypeCodeImpression   = @"imp";
NSString * const CLXEventTypeCodeBidRequest   = @"bidreq";
NSString * const CLXEventTypeCodeSDKError     = @"error";
NSString * const CLXEventTypeCodeSDKCrash     = @"crash";
NSString * const CLXEventTypeCodeSDKMetrics   = @"sdkmetricenc";

/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXIlrdService;
@class CLXEventTelemetryTracker;

/**
 * Collects ILRD impression events from CLXIlrdService and reports them as
 * adRevenue telemetry events. SDK identity rides the telemetry envelope; CX
 * auction correlation rides the sealed auction token when a no-fill auction
 * preceded the mediator impression.
 *
 * Observes CLXAuctionResultNotification to track no-fill auctions per ad format.
 * When an ILRD impression arrives for a format that had a no-fill, the event
 * carries that auction's sealed token (one-shot, then consumed).
 */
@interface CLXIlrdTracker : NSObject

- (instancetype)initWithIlrdService:(CLXIlrdService *)ilrdService
              eventTelemetryTracker:(CLXEventTelemetryTracker *)eventTelemetryTracker;

- (void)start;
- (void)stop;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

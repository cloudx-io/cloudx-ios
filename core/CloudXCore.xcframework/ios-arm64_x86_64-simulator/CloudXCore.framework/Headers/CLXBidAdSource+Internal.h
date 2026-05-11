/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidAdSource+Internal.h
 * @brief Internal collaborators on `CLXBidAdSource` exposed for tests.
 * @discussion `bidNetworkService` and `winLossTracker` are private
 *             implementation details declared in `CLXBidAdSource.m`'s class
 *             extension. Tests need to inject fakes for these collaborators
 *             without using `setValue:forKey:`, which fails silently at
 *             runtime if the underlying property is renamed. Re-declaring
 *             the properties here gives tests a compile-time-checked seam.
 *             Not exported in the public umbrella header.
 */

#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXWinLossTracker.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXBidAdSource (Internal)

/// Network service used to issue auction bid requests. Production wiring
/// resolves this via `CLXDIContainer`; tests inject a fake conforming to
/// `CLXBidNetworkService`.
@property (nonatomic, strong) id<CLXBidNetworkService> bidNetworkService;

/// Win/loss tracker used to report adapter creation outcomes to the SSP.
/// Production wiring uses `[CLXWinLossTracker shared]`; tests inject a
/// fake conforming to `CLXWinLossTracking`.
@property (nonatomic, strong) id<CLXWinLossTracking> winLossTracker;

@end

NS_ASSUME_NONNULL_END

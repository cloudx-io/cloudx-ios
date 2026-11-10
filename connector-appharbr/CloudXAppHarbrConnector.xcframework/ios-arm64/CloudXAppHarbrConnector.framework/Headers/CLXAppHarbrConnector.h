/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAppHarbrConnector.h
 * @brief CloudX ad-quality gate backed by the AppHarbr SDK.
 */

#import <Foundation/Foundation.h>

#import "CLXAppHarbrSDKBridge.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CLXAdQualityGate.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Ad-quality gate that forwards loaded ads to the AppHarbr SDK for analysis and
 * vetoes ads AppHarbr blocks.
 *
 * @brief AppHarbr-backed ad-quality gate; self-registers at `+load`.
 *
 * @discussion AppHarbr validates the concrete ad class and rejects a mediation
 * wrapper, so the connector hands it the ad network's own ad object, which it
 * finds on the adapter itself. Adapters need no AppHarbr-specific code. When the
 * connector can't identify the network's object, or the analyzer declines it,
 * AppHarbr reports @c InvalidAdObject and the ad is allowed through (fail-open).
 *
 * Registered with the CloudX SDK automatically at load time (see
 * @c CloudXAppHarbrConnectorRegister); the publisher's only step is adding this
 * module as a dependency. The publisher already integrates and initializes the
 * AppHarbr SDK with their own API key — this module never initializes AppHarbr.
 * When AppHarbr is not ready (@c isReady == NO), analysis is skipped and every ad
 * is allowed through (fail-open).
 */
@interface CLXAppHarbrConnector : NSObject <CLXAdQualityGate>

/**
 * Designated initializer.
 *
 * @param bridge The seam over the AppHarbr SDK; production passes the real bridge, tests
 *        inject a fake. May be nil: the registration path passes nil when the production
 *        bridge class is not linked (e.g. the unit-test target), and the connector degrades to
 *        its documented fail-open behavior (every ad allowed).
 * @return A connector.
 */
- (instancetype)initWithBridge:(nullable id<CLXAppHarbrSDKBridge>)bridge NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

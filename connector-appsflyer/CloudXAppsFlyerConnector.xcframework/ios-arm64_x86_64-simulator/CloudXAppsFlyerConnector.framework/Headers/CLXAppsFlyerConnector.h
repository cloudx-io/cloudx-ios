/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAppsFlyerConnector.h
 * @brief CloudX ad-revenue integration for AppsFlyer.
 */

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CLXAdRevenueDelegate.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Forwards every CloudX-won impression to AppsFlyer's ad-revenue API.
 *
 * Registered with the CloudX SDK automatically at load time (see `CloudXAppsFlyerConnectorRegister`);
 * the publisher's only step is adding this module as a dependency. The publisher already integrates
 * and initializes AppsFlyer with their own dev key — this module never initializes AppsFlyer and
 * depends on the AppsFlyer SDK with a broad version range, using the publisher's runtime version.
 */
@interface CLXAppsFlyerConnector : NSObject <CLXAdRevenueDelegate>
@end

NS_ASSUME_NONNULL_END

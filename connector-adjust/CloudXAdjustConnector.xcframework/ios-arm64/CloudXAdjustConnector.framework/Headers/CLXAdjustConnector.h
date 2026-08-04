/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdjustConnector.h
 * @brief CloudX ad-revenue connector for Adjust.
 */

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CLXAdRevenueDelegate.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Forwards every CloudX-won impression to Adjust's ad-revenue API.
 *
 * Registered with the CloudX SDK automatically at load time (see `CloudXAdjustConnectorRegister`);
 * the publisher's only step is adding this module as a dependency. The publisher already integrates
 * and initializes Adjust with their own app token — this module never initializes Adjust and
 * depends on the Adjust SDK with a broad version range, using the publisher's runtime version.
 */
@interface CLXAdjustConnector : NSObject <CLXAdRevenueDelegate>
@end

NS_ASSUME_NONNULL_END

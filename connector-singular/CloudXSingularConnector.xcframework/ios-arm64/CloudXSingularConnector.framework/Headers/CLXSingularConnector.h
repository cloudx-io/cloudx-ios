/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSingularConnector.h
 * @brief CloudX ad-revenue connector for Singular.
 */

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CLXAdRevenueDelegate.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Forwards every CloudX-won impression to Singular's ad-revenue API.
 *
 * Registered with the CloudX SDK automatically at load time (see `CloudXSingularConnectorRegister`);
 * the publisher's only step is adding this module as a dependency. The publisher already integrates
 * and initializes Singular with their own API key — this module never initializes Singular and
 * depends on the Singular SDK by version floor, using the publisher's runtime version.
 */
@interface CLXSingularConnector : NSObject <CLXAdRevenueDelegate>
@end

NS_ASSUME_NONNULL_END

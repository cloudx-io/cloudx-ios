/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Device-sourced wire signals. Mirrors server SDKBlock field-for-field. */
@interface CLXSDKBlock : NSObject

@property (nonatomic, copy) NSString *appBundle;
@property (nonatomic, copy, nullable) NSString *appVersion;
@property (nonatomic, copy, nullable) NSString *appBuildNumber;
@property (nonatomic, copy, nullable) NSString *appDistribution;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy, nullable) NSNumber *adapterApiVersion;
@property (nonatomic, copy, nullable) NSString *pluginVersion;
@property (nonatomic, copy) NSString *deviceOS;
@property (nonatomic, copy) NSString *osVersion;
@property (nonatomic, copy) NSString *deviceMake;
@property (nonatomic, copy) NSString *deviceModel;
@property (nonatomic, copy, nullable) NSString *deviceType;
@property (nonatomic, copy, nullable) NSString *deviceLanguage;
@property (nonatomic, copy, nullable) NSString *deviceUA;
@property (nonatomic, copy, nullable) NSNumber *deviceScreenW;
@property (nonatomic, copy, nullable) NSNumber *deviceScreenH;
@property (nonatomic, copy, nullable) NSNumber *devicePPI;
@property (nonatomic, copy, nullable) NSNumber *screenScale;
@property (nonatomic, copy, nullable) NSNumber *deviceConnectionType;
@property (nonatomic, copy, nullable) NSNumber *isVirtualDevice;
@property (nonatomic, copy, nullable) NSNumber *geoUtcoffset;
/** Process-relative uptime (ms) at block-creation time, EXCLUDING deep sleep; clock-stable.
    Commensurate with latency durations. Mirrors server SDKBlock. */
@property (nonatomic, copy, nullable) NSNumber *appUptimeMs;
/** Process-relative uptime (ms) at block-creation time, INCLUDING deep sleep; clock-stable.
    Real elapsed time since launch. Mirrors server SDKBlock. NOT commensurate with the current
    session-age / time-to-first-ad metrics, which are computed on a sleep-EXCLUDING base — do not
    subtract those from this value. */
@property (nonatomic, copy, nullable) NSNumber *appUptimeWallMs;

- (NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END

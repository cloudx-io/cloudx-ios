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

- (NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END

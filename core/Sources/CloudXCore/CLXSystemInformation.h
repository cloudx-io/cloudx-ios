/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file SystemInformation.h
 * @brief Provides system information functionality for the CloudX SDK
 * @details This class provides access to various system information properties
 *          including device type, SDK version, app version, and identifiers.
 *          The DeviceType enum represents the type of device (phone, tablet, or unknown).
 */

#import <Foundation/Foundation.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DeviceType) {
    DeviceTypePhone = 4,
    DeviceTypeTablet = 5,
    DeviceTypeUnknown = 1
};

/**
 * @class SystemInformation
 * @brief Singleton class providing system information
 * @discussion This class provides access to various system information needed by the SDK,
 * including device identifiers, OS version, and SDK version.
 */
@interface CLXSystemInformation : NSObject

/** Shared instance of SystemInformation */
@property (class, nonatomic, readonly) CLXSystemInformation *shared;

/** The device type (phone, tablet, or unknown) */
@property (nonatomic, readonly) DeviceType deviceType;

/** The SDK version */
@property (nonatomic, readonly) NSString *sdkVersion;

/** The SDK bundle identifier */
@property (nonatomic, readonly) NSString *sdkBundle;

/** The app bundle identifier */
@property (nonatomic, readonly) NSString *appBundleIdentifier;

/** The app version */
@property (nonatomic, readonly) NSString *appVersion;

/** The OS version */
@property (nonatomic, readonly) NSString *osVersion;

/** The IDFA (Identifier for Advertisers) */
@property (nonatomic, readonly, nullable) NSString *idfa;

/** The IDFV (Identifier for Vendor) */
@property (nonatomic, readonly, nullable) NSString *idfv;

/** Whether Do Not Track is enabled */
@property (nonatomic, readonly) BOOL dnt;

/** Whether Limit Ad Tracking is enabled */
@property (nonatomic, readonly) BOOL lat;

/** The OS name */
@property (nonatomic, readonly) NSString *os;

/** The device model */
@property (nonatomic, readonly) NSString *model;

/** The system version */
@property (nonatomic, readonly) NSString *systemVersion;

/** The hardware version */
@property (nonatomic, readonly) NSString *hardwareVersion;

/** The display manager */
@property (nonatomic, readonly) NSString *displayManager;


@end

NS_ASSUME_NONNULL_END

// Helper function to convert DeviceType enum to NSString
FOUNDATION_EXPORT NSString * _Nonnull DeviceTypeToString(DeviceType type); 
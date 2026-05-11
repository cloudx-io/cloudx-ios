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
#import <CoreGraphics/CoreGraphics.h>
#import <CloudXCore/CLXExport.h>

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
CLX_PUBLIC_ADAPTER
@interface CLXSystemInformation : NSObject

/** Shared instance of SystemInformation */
@property (class, nonatomic, readonly) CLXSystemInformation *shared;

/** The device type (phone, tablet, or unknown) */
@property (nonatomic, readonly) DeviceType deviceType;

/** The SDK version */
@property (nonatomic, readonly) NSString *sdkVersion;

/** The SDK bundle identifier */
@property (nonatomic, readonly) NSString *sdkBundle;

/** The app bundle identifier (real main bundle) */
@property (nonatomic, readonly) NSString *appBundleIdentifier;

/** The effective app bundle identifier, honoring the emulator bundle override on simulator builds. */
@property (nonatomic, readonly) NSString *effectiveAppBundleIdentifier;

/** The app version name (CFBundleShortVersionString, e.g. "1.2.3"). */
@property (nonatomic, readonly) NSString *appVersion;

/** The app build number (CFBundleVersion, e.g. "42" or "2024.01.15.1"). */
@property (nonatomic, readonly) NSString *appBuildNumber;

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

/** The display manager */
@property (nonatomic, readonly) NSString *displayManager;

/**
 * @brief User's device language as a BCP 47 tag (e.g. `"en-US"`, `"zh-Hant-HK"`).
 * @return Non-nil language tag, empty string only if the system returns no preferred language.
 * @discussion Memoized at shared-instance init. Stable for the SDK session lifetime.
 */
@property (nonatomic, copy, readonly) NSString *deviceLanguage;

/**
 * @brief Pixel density scale factor for the main screen (e.g. 2.0, 3.0).
 * @discussion Corresponds to `UIScreen.mainScreen.scale`. `[UIScreen mainScreen]` must
 *             be accessed on the main thread on recent iOS runtimes, so the value is
 *             captured once at shared-instance init (dispatched to main if necessary)
 *             and returned from cache thereafter. Stable for the SDK session lifetime.
 */
@property (nonatomic, readonly) CGFloat screenScale;

/**
 * @brief YES when the SDK is running in the iOS Simulator; NO on physical devices.
 * @discussion Implemented as a `TARGET_OS_SIMULATOR` compile-time guard. Safe across
 *             xcframework distribution because Apple ships separate binary slices per
 *             platform — the device slice returns NO and the simulator slice returns YES.
 */
@property (nonatomic, readonly) BOOL isVirtualDevice;

/**
 * @brief Classified distribution channel for the host app.
 * @discussion Returns one of: `"simulator"`, `"debug"`, `"testflight"`, `"enterprise"`,
 *             `"appstore"`, or `nil` when the classifier cannot match. Derived from the
 *             receipt path + `embedded.mobileprovision` presence + compile-time guards.
 *             Note: `"appstore"` covers both real App Store distribution and notarized
 *             EU alternative-marketplace distribution — Apple's receipt system produces
 *             identical signatures for both.
 */
@property (nonatomic, copy, readonly, nullable) NSString *appDistribution;

/**
 * @brief Convenience — YES iff `appDistribution` equals `"appstore"`.
 * @discussion Preserved for existing callers. Prefer reading `appDistribution` directly
 *             when the call site needs to distinguish TestFlight / enterprise / debug.
 */
@property (nonatomic, readonly) BOOL isAppStoreEnvironment;

@end

NS_ASSUME_NONNULL_END

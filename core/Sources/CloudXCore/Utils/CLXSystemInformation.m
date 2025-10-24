/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file SystemInformation.m
 * @brief Implementation of system information functionality
 */

#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXVersion.h>
#import <UIKit/UIKit.h>
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXLogger.h>

static CLXSystemInformation *sharedInstance = nil;

@implementation CLXSystemInformation

@synthesize deviceType = _deviceType;
@synthesize sdkVersion = _sdkVersion;
@synthesize sdkBundle = _sdkBundle;
@synthesize appBundleIdentifier = _appBundleIdentifier;
@synthesize appVersion = _appVersion;
@synthesize osVersion = _osVersion;
@synthesize idfa = _idfa;
@synthesize idfv = _idfv;
@synthesize dnt = _dnt;
@synthesize lat = _lat;
@synthesize os = _os;
@synthesize model = _model;
@synthesize systemVersion = _systemVersion;
@synthesize hardwareVersion = _hardwareVersion;
@synthesize displayManager = _displayManager;
@synthesize isAppStoreEnvironment = _isAppStoreEnvironment;

+ (CLXSystemInformation *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (DeviceType)deviceType {
    UIUserInterfaceIdiom idiom = [UIDevice currentDevice].userInterfaceIdiom;
    switch (idiom) {
        case UIUserInterfaceIdiomPad:
            return DeviceTypeTablet;
        case UIUserInterfaceIdiomPhone:
            return DeviceTypePhone;
        default:
            return DeviceTypeUnknown;
    }
}

- (NSString *)sdkVersion {
    return CLXSDKVersion;
}

- (NSString *)sdkBundle {
    return [[NSBundle bundleForClass:NSClassFromString(@"CloudXCore")] bundleIdentifier] ?: @"";
}

- (NSString *)appBundleIdentifier {
    return [[NSBundle mainBundle] bundleIdentifier] ?: @"";
}

- (NSString *)appVersion {
    return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] description] ?: @"";
}

- (NSString *)osVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)idfa {
    return [CLXAdTrackingService idfa];
}

- (NSString *)idfv {
    return [[UIDevice currentDevice] identifierForVendor].UUIDString;
}

- (BOOL)dnt {
    return [CLXAdTrackingService dnt];
}

- (BOOL)lat {
    return [CLXAdTrackingService dnt];
}

- (NSString *)os {
    return @"iOS";
}

- (NSString *)model {
    return [UIDevice deviceIdentifier];
}

- (NSString *)systemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)hardwareVersion {
    return [UIDevice deviceGeneration];
}

- (NSString *)displayManager {
    return @"CLOUDX";
}

- (BOOL)isAppStoreEnvironment {
    #ifdef DEBUG
    // All debug builds are non-production
    return NO;
    #else
    // Check if running on simulator
    #if TARGET_IPHONE_SIMULATOR
    return NO;
    #endif
    
    // Check for App Store receipt
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSString *receiptPath = receiptURL.path;
    
    // TestFlight apps have receipts in sandboxReceipt, App Store apps in receipt
    if (receiptPath && [receiptPath containsString:@"sandboxReceipt"]) {
        return NO;
    }
    
    // Check if receipt exists and is a production receipt
    if (receiptPath && [[NSFileManager defaultManager] fileExistsAtPath:receiptPath]) {
        // Check for embedded.mobileprovision (ad-hoc or enterprise distribution)
        NSString *provisionPath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
        if (provisionPath) {
            // App Store builds strip this file
            return NO;
        }
        
        // Receipt exists and no provisioning profile - likely App Store
        return YES;
    }
    
    // No receipt or unrecognized setup - assume non-production
    return NO;
    #endif
}

@end

NSString * _Nonnull DeviceTypeToString(DeviceType type) {
    switch (type) {
        case DeviceTypePhone:
            return @"phone";
        case DeviceTypeTablet:
            return @"tablet";
        case DeviceTypeUnknown:
        default:
            return @"unknown";
    }
} 
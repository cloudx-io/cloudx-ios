/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file SystemInformation.m
 * @brief Implementation of system information functionality
 */

#import <CloudXCore/CLXSystemInformation.h>
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
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.cloudx.sdk.core"];
    NSString *version = [bundle objectForInfoDictionaryKey:@"CloudXMarketingVersion"];
    if (version) {
        return version;
    }
    
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"CloudXSDK" withExtension:@"bundle"];
    if (bundleURL) {
        NSBundle *sdkBundle = [NSBundle bundleWithURL:bundleURL];
        version = [sdkBundle objectForInfoDictionaryKey:@"CloudXMarketingVersion"];
        if (version) {
            return version;
        }
    }
    
    version = [[NSBundle bundleForClass:NSClassFromString(@"CloudXCore")] objectForInfoDictionaryKey:@"CloudXMarketingVersion"];
    if (version) {
        return version;
    }
    
    return @"0.0.0";
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
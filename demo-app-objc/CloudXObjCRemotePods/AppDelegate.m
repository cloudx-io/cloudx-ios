//
//  AppDelegate.m
//  CloudXObjCRemotePods
//
//  Created by Bryan Boyko on 5/22/25.
//

#import "AppDelegate.h"
#import <CloudXCore/CloudXCore.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>
@import AppLovinSDK;
#import "DemoAppLogger.h"
#import "AdDemoTabViewController.h"
#import "CLXBidResponseSwizzler.h"

static NSString *const kAppLovinSdkKey = @"CZ_XxS0v1pDXVdV2yDXaxO4dOV8849QwTq7iDFlGLsJZngU95AEyaq2z8lF0GRlSvdknWDpTDp1GmprFC1FiJ1";

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Enable verbose logging for demo app
    [CloudXCore setMinLogLevel:CLXLogLevelVerbose];
    [CloudXCore setLoggingEmojisEnabled:YES];
    [CloudXCore setLoggingTimestampsEnabled:YES];
    
    // Enable bid response swizzling if the QA toggle was previously enabled
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DemoApp.PrintBidResponse"]) {
        [CLXBidResponseSwizzler enableSwizzling];
        NSLog(@"🔍 Print Full Bid Response enabled from previous session");
    }
    
    // Request App Tracking Transparency permission
    [self requestAppTrackingTransparencyPermission];

    // Initialize AppLovin SDK for ILRD testing
    [self initializeAppLovinSdk];

    // Set up window with AdDemoTabViewController (the real UI)
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[AdDemoTabViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)requestAppTrackingTransparencyPermission {
    // iOS 14+ ATT compliance
    if (@available(iOS 14, *)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                switch (status) {
                    case ATTrackingManagerAuthorizationStatusAuthorized:
                        [[DemoAppLogger sharedInstance] logMessage:@"App Tracking authorized"];
                        break;
                    case ATTrackingManagerAuthorizationStatusDenied:
                        [[DemoAppLogger sharedInstance] logMessage:@"App Tracking denied"];
                        break;
                    case ATTrackingManagerAuthorizationStatusNotDetermined:
                        [[DemoAppLogger sharedInstance] logMessage:@"App Tracking not determined"];
                        break;
                    case ATTrackingManagerAuthorizationStatusRestricted:
                        [[DemoAppLogger sharedInstance] logMessage:@"App Tracking restricted"];
                        break;
                    default:
                        break;
                }
            }];
        });
    }
}

- (void)initializeAppLovinSdk {
    ALSdkInitializationConfiguration *config =
        [ALSdkInitializationConfiguration configurationWithSdkKey:kAppLovinSdkKey builderBlock:^(ALSdkInitializationConfigurationBuilder *builder) {
            builder.mediationProvider = ALMediationProviderMAX;
        }];

    ALSdk *sdk = [ALSdk shared];
    sdk.settings.verboseLoggingEnabled = YES;
    [sdk initializeWithConfiguration:config completionHandler:^(ALSdkConfiguration *sdkConfig) {
        NSLog(@"AppLovin SDK initialized");
    }];
}

@end

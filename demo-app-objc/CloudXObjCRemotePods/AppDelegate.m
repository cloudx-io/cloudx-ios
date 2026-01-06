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
#import "DemoAppLogger.h"
#import "AdDemoTabViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Enable verbose logging for demo app
    [CloudXCore setLoggingEnabled:YES];
    [CloudXCore setMinLogLevel:CLXLogLevelVerbose];
    [CloudXCore setLoggingEmojisEnabled:YES];
    [CloudXCore setLoggingTimestampsEnabled:YES];
    
    // Auto-clear all privacy test settings on every launch
    // This ensures clean state for testing and prevents GPP settings from persisting
    [self clearAllPrivacyTestSettings];
    
    // Request App Tracking Transparency permission
    [self requestAppTrackingTransparencyPermission];
    
    // Set up window with AdDemoTabViewController (the real UI)
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[AdDemoTabViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)clearAllPrivacyTestSettings {
    // Clear all IAB standard privacy settings to ensure clean state
    // This prevents GPP and other privacy scenarios from persisting across app launches
    // CloudX SDK reads from these IAB standard UserDefaults keys automatically
    
    // Clear IAB GPP UserDefaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABGPP_HDR_GppString"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABGPP_GppSID"];
    
    // Clear IAB TCF UserDefaults (GDPR)
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_TCString"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_gdprApplies"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABTCF_PurposeConsents"];
    
    // Clear IAB US Privacy UserDefaults (CCPA)
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"IABUSPrivacy_String"];
    
    // Also clear any environment overrides
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CLXDemoEnvironment"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[DemoAppLogger sharedInstance] logMessage:@"✅ Auto-cleared all privacy test settings on app launch"];
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


@end

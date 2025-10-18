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

@interface AppDelegate ()

@end

@implementation AppDelegate

- (UIWindow *)window {
    if (!_window) {
        // Fallback window for Meta SDK compatibility
        // In scene-based apps, the actual window is managed by SceneDelegate
        // but some SDKs still expect AppDelegate to have a window property
        if (@available(iOS 13.0, *)) {
            // Try to get the key window from active scene
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            return window;
                        }
                    }
                }
            }
            // If no key window found, return the first available window
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.windows.count > 0) {
                    return scene.windows.firstObject;
                }
            }
        }
        
        // Final fallback - create a basic window if none exists
        _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    return _window;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Enable verbose logging for demo app
    [CloudXCore setLoggingEnabled:YES];
    
    // DEMO APP ONLY: Force test mode for all bid requests
    // This internal flag ensures test=1 is always set in bid requests for demo app
    // regardless of build configuration (simulator/device, debug/release)
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLXCore_Internal_ForceTestMode"];
    
    // DEMO APP ONLY: Enable Meta test mode for release builds
    // This ensures Meta SDK registers device as test device and serves test ads
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLXMetaTestModeEnabled"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Auto-clear all privacy test settings on every launch
    // This ensures clean state for testing and prevents COPPA/GPP settings from persisting
    [self clearAllPrivacyTestSettings];
    
    // Request App Tracking Transparency permission
    [self requestAppTrackingTransparencyPermission];
    
    return YES;
}

- (void)clearAllPrivacyTestSettings {
    // Clear all CloudXCore privacy test settings to ensure clean state
    // This prevents COPPA, GPP, and other privacy scenarios from persisting across app launches
    [CloudXCore setIsAgeRestrictedUser:NO];
    [CloudXCore setGPPString:nil];
    [CloudXCore setGPPSid:nil];
    [CloudXCore setIsUserConsent:YES];
    [CloudXCore setIsDoNotSell:NO];
    [CloudXCore setCCPAPrivacyString:nil];
    
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


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end

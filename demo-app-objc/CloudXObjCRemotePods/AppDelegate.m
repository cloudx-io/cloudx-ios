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
#import "CLXBidResponseSwizzler.h"

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


@end

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


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Request App Tracking Transparency permission
    [self requestAppTrackingTransparencyPermission];
    
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

//
//  AppDelegate.m
//  CloudXObjCRemotePods
//
//  Created by Bryan Boyko on 5/22/25.
//

#import "AppDelegate.h"
#import <CloudXCore/CloudXCore.h>
#import "OptionsViewController.h"
#import "CLXDeepLinkRouter.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    // Enable verbose logging for demo app
    [CloudXCore setMinLogLevel:CLXLogLevelVerbose];
    [CloudXCore setLoggingEmojisEnabled:YES];
    [CloudXCore setLoggingTimestampsEnabled:YES];

    /*
     * The Options screen picks the demo flow and makes no SDK calls. General
     * (AdDemoTabViewController) requests App Tracking Transparency when it opens.
     */
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[OptionsViewController alloc] init];
    [self.window makeKeyAndVisible];

    [CLXDeepLinkRouter handleLaunchArguments];

    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [CLXDeepLinkRouter handleURL:url];
}

@end

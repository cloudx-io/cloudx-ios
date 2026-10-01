//
//  AppDelegate.swift
//  CloudXSwiftRemotePods
//
//  Created by Bryan Boyko on 5/25/25.
//

import UIKit
import CloudXCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Enable verbose logging for demo app
        CloudXCore.setMinLogLevel(.verbose)
        CloudXCore.setLoggingEmojisEnabled(true)
        CloudXCore.setLoggingTimestampsEnabled(true)

        /*
         * The Options screen picks the demo flow and makes no SDK calls. General
         * (AdDemoTabViewController) requests App Tracking Transparency when it opens.
         */
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = OptionsViewController()
        self.window?.makeKeyAndVisible()

        DeepLinkRouter.handleLaunchArguments()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return DeepLinkRouter.handleURL(url)
    }
}

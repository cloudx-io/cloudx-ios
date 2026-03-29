//
//  AppDelegate.swift
//  CloudXSwiftRemotePods
//
//  Created by Bryan Boyko on 5/25/25.
//

import UIKit
import CloudXCore
import AppTrackingTransparency
import AdSupport

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Enable verbose logging for demo app
        CloudXCore.setMinLogLevel(.verbose)
        CloudXCore.setLoggingEmojisEnabled(true)
        CloudXCore.setLoggingTimestampsEnabled(true)
        
        // Request App Tracking Transparency permission
        requestAppTrackingTransparencyPermission()
        
        // Set up window with AdDemoTabViewController (the real UI)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = AdDemoTabViewController()
        self.window?.makeKeyAndVisible()
        
        DeepLinkRouter.handleLaunchArguments()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return DeepLinkRouter.handleURL(url)
    }
    
    private func requestAppTrackingTransparencyPermission() {
        // iOS 14+ ATT compliance
        if #available(iOS 14, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        DemoAppLogger.sharedInstance.logMessage("App Tracking authorized")
                    case .denied:
                        DemoAppLogger.sharedInstance.logMessage("App Tracking denied")
                    case .notDetermined:
                        DemoAppLogger.sharedInstance.logMessage("App Tracking not determined")
                    case .restricted:
                        DemoAppLogger.sharedInstance.logMessage("App Tracking restricted")
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}

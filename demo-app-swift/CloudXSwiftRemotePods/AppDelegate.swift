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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Request App Tracking Transparency permission
        requestAppTrackingTransparencyPermission()
        
        return true
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

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


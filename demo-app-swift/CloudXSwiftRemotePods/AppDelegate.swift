//
//  AppDelegate.swift
//  CloudXSwiftRemotePods
//
//  Created by Bryan Boyko on 5/25/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Check all loaded classes for CloudX prefix
        let classes = objc_getClassList(nil, 0)
        let buffer = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(classes))
        defer { buffer.deallocate() }
        
        let autoreleasingBuffer = AutoreleasingUnsafeMutablePointer<AnyClass>(buffer)
        let count = Int(objc_getClassList(autoreleasingBuffer, classes))
        
        print("\n[DEBUG] All CloudX classes found:")
        for i in 0..<count {
            let className = NSStringFromClass(buffer[i])
            if className.contains("CloudX") {
                print("[DEBUG] Found class: \(className)")
            }
        }
        return true
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


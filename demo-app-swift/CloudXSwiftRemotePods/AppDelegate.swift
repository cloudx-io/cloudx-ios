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
    
    @objc var window: UIWindow? {
        // Fallback window for Meta SDK compatibility
        // In scene-based apps, the actual window is managed by SceneDelegate
        // but some SDKs still expect AppDelegate to have a window property
        if #available(iOS 13.0, *) {
            // Try to get the key window from active scene
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                if windowScene.activationState == .foregroundActive {
                    for window in windowScene.windows {
                        if window.isKeyWindow {
                            return window
                        }
                    }
                }
            }
            // If no key window found, return the first available window
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                if !windowScene.windows.isEmpty {
                    return windowScene.windows.first
                }
            }
        }
        
        // Final fallback - create a basic window if none exists
        let fallbackWindow = UIWindow(frame: UIScreen.main.bounds)
        return fallbackWindow
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Enable verbose logging for demo app
        CloudXCore.setMinLogLevel(.verbose)
        CloudXCore.setLoggingEmojisEnabled(true)
        
        // Auto-clear all privacy test settings on every launch
        // This ensures clean state for testing and prevents GPP settings from persisting
        clearAllPrivacyTestSettings()
        
        // Enable bid response swizzling if the QA toggle was previously enabled
        if UserDefaults.standard.bool(forKey: "DemoApp.PrintBidResponse") {
            CLXBidResponseSwizzler.enableSwizzling()
            print("🔍 Print Full Bid Response enabled from previous session")
        }
        
        // Request App Tracking Transparency permission
        requestAppTrackingTransparencyPermission()
        
        return true
    }
    
    private func clearAllPrivacyTestSettings() {
        // Clear all IAB standard privacy settings to ensure clean state
        // This prevents GPP and other privacy scenarios from persisting across app launches
        // CloudX SDK reads from these IAB standard UserDefaults keys automatically
        
        // Clear IAB GPP UserDefaults
        UserDefaults.standard.removeObject(forKey: "IABGPP_HDR_GppString")
        UserDefaults.standard.removeObject(forKey: "IABGPP_GppSID")
        
        // Clear IAB TCF UserDefaults (GDPR)
        UserDefaults.standard.removeObject(forKey: "IABTCF_TCString")
        UserDefaults.standard.removeObject(forKey: "IABTCF_gdprApplies")
        UserDefaults.standard.removeObject(forKey: "IABTCF_PurposeConsents")
        
        // Clear IAB US Privacy UserDefaults (CCPA)
        UserDefaults.standard.removeObject(forKey: "IABUSPrivacy_String")
        
        // Also clear any environment overrides
        UserDefaults.standard.removeObject(forKey: "CLXDemoEnvironment")
        UserDefaults.standard.synchronize()
        
        DemoAppLogger.sharedInstance.logMessage("✅ Auto-cleared all privacy test settings on app launch")
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

// MARK: - Notification Names
extension NSNotification.Name {
    static let sdkInitialized = NSNotification.Name("CloudXSDKInitialized")
}


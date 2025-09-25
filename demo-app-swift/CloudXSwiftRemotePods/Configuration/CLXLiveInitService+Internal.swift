/*
 * ⚠️  INTERNAL TESTING ONLY - NOT FOR PUBLIC SDK USE  ⚠️
 *
 * This extension extends CLXLiveInitService with internal testing methods
 * that are NOT part of the public SDK API. These methods are intended
 * solely for internal development, testing, and debugging purposes.
 *
 * DO NOT USE THESE METHODS IN PRODUCTION APPLICATIONS!
 * 
 * Public applications should use the standard CloudXCore initialization
 * methods provided in the main SDK interface.
 *
 * These internal methods may be removed, modified, or deprecated at any
 * time without notice and are not covered by SDK compatibility guarantees.
 */

import Foundation
import CloudXCore

/**
 * Internal methods for CLXLiveInitService to support custom initialization URLs
 * This extension exposes internal functionality for demo purposes only.
 * Production apps should use the standard initialization methods.
 */
extension CLXLiveInitService {
    
    /**
     * Initializes the SDK with a custom initialization URL
     * - Parameters:
     *   - appKey: The application key for SDK initialization
     *   - customInitURL: Custom URL for SDK initialization endpoint
     *   - completion: Completion handler called with the SDK configuration or error
     * - Note: This method allows overriding the default initialization URL for testing different environments
     */
    func initSDK(withAppKey appKey: String, 
                 customInitURL: String, 
                 completion: @escaping (CLXSDKConfigResponse?, Error?) -> Void) {
        
        print("🚀 [LiveInitService+Internal] initSDKWithAppKey called with custom URL - AppKey: \(appKey), URL: \(customInitURL)")
        
        // Create a temporary network service with the custom URL
        let cloudxSession = URLSession.cloudxSession(withIdentifier: "init-internal")
        let networkService = CLXSDKInitNetworkService(baseURL: customInitURL, urlSession: cloudxSession)
        
        networkService.initSDK(withAppKey: appKey) { config, error in
            if let error = error {
                print("❌ [LiveInitService+Internal] Custom NetworkInitService failed with error: \(error)")
            } else {
                print("✅ [LiveInitService+Internal] Custom NetworkInitService succeeded")
            }
            
            completion(config, error)
        }
    }
    
    /**
     * Initialize SDK with custom URL and hashed user ID
     * - Parameters:
     *   - appKey: The application key for SDK initialization
     *   - customInitURL: Custom URL for SDK initialization endpoint
     *   - hashedUserId: The hashed user ID for SDK initialization
     *   - completion: Completion handler called with success status and error
     * - Note: This method combines custom URL initialization with standard SDK initialization flow
     */
    func initSDK(withAppKey appKey: String, 
                 customInitURL: String, 
                 hashedUserId: String, 
                 completion: @escaping (Bool, Error?) -> Void) {
        
        initSDK(withAppKey: appKey, customInitURL: customInitURL) { config, error in
            // For demo purposes, we'll consider the config fetch as success and let the main SDK handle the rest
            let success = config != nil && error == nil
            completion(success, error)
        }
    }
}
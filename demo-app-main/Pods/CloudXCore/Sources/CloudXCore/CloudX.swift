//
//  CloudX.swift
//  CloudXCore
//
//  Created by bkorda on 08.02.2024.
//

import Foundation
import UIKit

protocol CloudXPublicAPI {
    
    func initSDK(appKey: String, completion: ((Bool, CloudXError?) -> Void)?)
    func initSDK(appKey: String) async throws -> Bool
    func initSDK(appKey: String, hashedUserID: String) async throws -> Bool
    func provideUserDetails(hashedUserID: String)
    func useHashedKeyValue(key: String, value: String)
    func useKeyValues(userDictionary: [String: String])
    func useBidderKeyValue(bidder: String, key: String, value: String)
    func createBanner(placement: String, viewController: UIViewController, delegate: CloudXBannerDelegate?) -> CloudXBannerAdView?
    func createInterstitial(placement: String, delegate: CloudXInterstitialDelegate?) -> CloudXInterstitial?
    func createRewarded(placement: String, delegate: CloudXRewardedDelegate?) -> CloudXRewardedInterstitial?
    func createNativeAd(placement: String, viewController: UIViewController, delegate: CloudXNativeDelegate?) -> CloudXNativeAdView?
    var sdkVersion: String { get }
    
}

/// The main class of the CloudX SDK.
/// Use this class to initialise the SDK and create ads.
@objc public class CloudX: NSObject, CloudXPublicAPI {
    
    private enum SDKInitialisationStage {
        
        case notStarted
        case inProgress
        case initialised
        
    }
    
    @Service private var initService: InitService
    private var sdkConfig: SDKConfig.Response?
    private var sdkInitStage: SDKInitialisationStage = .notStarted
    private var appKey: String?
    
    private var adNetworkFactories: AdNetworkFactories?
    private var adNetworkConfigs: [String : SDKConfig.Response.Bidder]?
    private var adPlacements: [String : SDKConfig.Response.Placement]?
    
    private var adFactory: PublisherAdFactory = PublisherAdFactory()
    private var reportingService: AdEventReporting?
    private let logger = Logger(category: "CloudX.swift")
    private let abTestValue = Double.random(in: 0.0..<1.0)
    private var abTestName = "RandomTest"
    private let defaultAuctionURL = "https://au-dev.cloudx.io/openrtb2/auction"
    @Service private var metricsTracker: MetricsTracker
    //@Service(.singleton) private var userDetailsService: UserDetailsService
    
    @objc public var userID: String?
    @objc public var logsData: [String: String] = [:]
    @objc public var isInitialised: Bool {
        sdkInitStage == .initialised
    }
    
    /// The shared instance of CloudX
    @objc public static let shared: CloudX = {
        let container = DIContainer.shared
        container.register(type: InitService.self, LiveInitService())
        container.register(type: GeoLocationService.self, GeoLocationService())
        container.register(type: MetricsTracker.self, MetricsTracker())
        //container.register(type: UserDetailsService.self, UserDetailsService())
        return CloudX()
    }()
    
    /// The version of the CloudX SDK
    public var sdkVersion: String {
        SystemInformation.shared.sdkVersion
    }
    
    static func sharedTest() -> CloudX {
        return CloudX()
    }
    
    /// Provide the user details for auction requests
    /// - Parameter hashedUserID: The hashedUserID provided by CloudX
    public func provideUserDetails(hashedUserID: String) {
        UserDefaults.standard.setValue(hashedUserID, forKey: "hashedUserID")
    }
    
    /// Provide the user details for auction requests
    /// - Parameter HashedKeyValue: The useHashedKeyValue provided by CloudX
    public func useHashedKeyValue(key: String, value: String) {
        UserDefaults.standard.setValue(key, forKey: "hashedKey")
        UserDefaults.standard.setValue(value, forKey: "hashedValue")
    }
    
    /// Provide the user details for auction requests
    /// - Parameter KeyValue: The useKeyValue provided by CloudX
    public func useKeyValues(userDictionary: [String: String]) {
        UserDefaults.standard.set(userDictionary, forKey: "userKeyValue")
    }
    
    /// Provide the user details for auction requests
    /// - Parameter BidderKeyValue: The useBidderKeyValue provided by CloudX
    public func useBidderKeyValue(bidder: String, key: String, value: String) {
        UserDefaults.standard.setValue(bidder, forKey: "userBidder")
        UserDefaults.standard.setValue(key, forKey: "userBidderKey")
        UserDefaults.standard.setValue(value, forKey: "userBidderValue")
    }
    
    /// Swift-only async/await initializer. Use this in Swift code with async/await. Not available to Objective-C.
    public func initSDK(appKey: String, hashedUserID: String) async throws -> Bool {
        UserDefaults.standard.setValue(hashedUserID, forKey: "hashedUserID")
        return try await initSDK(appKey: appKey)
    }
    
    /// Objective-C compatible initializer. Use this in Objective-C or in Swift code that prefers a completion handler.
    /// Calls the async initializer internally.
    @objc public func initSDKWithAppKey(_ appKey: String, hashedUserID: String, completion: @escaping (Bool, NSError?) -> Void) {
        Task {
            do {
                let result = try await self.initSDK(appKey: appKey, hashedUserID: hashedUserID)
                completion(result, nil)
            } catch {
                completion(false, error as NSError)
            }
        }
    }
    
    /// Initialise the SDK to start serving ads
    /// - Parameter appKey: The app key provided by CloudX
    /// - Returns: A boolean indicating if the SDK was initialised successfully
    public func initSDK(appKey: String) async throws -> Bool {
        logger.info("Start init SDK")
        switch sdkInitStage {
        case .notStarted:
            logger.debug("[DEBUG] SDK initialization not started yet")
            break
        case .inProgress:
            logger.error("[DEBUG] SDK initialization already in progress")
            throw CloudXError.sdkInitialisationInProgress
        case .initialised:
            logger.debug("[DEBUG] SDK already initialized")
            return true
        }
        sdkInitStage = .inProgress
        
        Task {
            await self.metricsTracker.trySendPendingMetrics()
        }
        
        var initMetrics = InitMetrics(appKey: appKey)
        defer {
            initMetrics.finish(sessionId: self.sdkConfig?.sessionID)
            CoreDataManager.shared.createInitMetrics(with: initMetrics)
        }
        do {
            self.appKey = appKey
            self.sdkConfig = try await self.initService.initSDK(appKey: appKey)
            self.logger.debug("[DEBUG] SDK config received: \(String(describing: self.sdkConfig))")
        } catch {
            self.logger.error("[DEBUG] Failed to init SDK: \(error)")
            sdkInitStage = .notStarted
            throw(error)
        }
        
        sdkInitStage = .initialised
        
        self.resolveAdapters()
        self.filterConfig()
        
        // initialising network bidder adapters
        let adNetworkInitializers = self.adNetworkFactories?.initialisers
        
        guard let adNetworkConfigs = sdkConfig?.bidders else {
            self.logger.error("[DEBUG] No ad network bidders found in SDK config. Initialization aborted.")
            return false
        }
        
        self.logger.info("[DEBUG] Initializing network bidder adapters. Total networks: \(adNetworkConfigs.count)")
        self.logger.debug("[DEBUG] Available initializers: \(String(describing: adNetworkInitializers?.keys))")
        
        for adNetworkConfig in adNetworkConfigs {
                    self.logger.debug("[DEBUG] Preparing to initialize network bidder adapter with config: \(adNetworkConfig)")
                    self.logger.debug("[DEBUG] Network name mapped: \(adNetworkConfig.networkNameMapped)")
                    guard let initializer = adNetworkInitializers?[adNetworkConfig.networkNameMapped] else {
                        self.logger.error("[DEBUG] No initializer found for network: \(adNetworkConfig.networkNameMapped). Skipping.")
                        continue
                    }
                    do {
                        self.logger.info("[DEBUG] Initializing network bidder adapter for network: \(adNetworkConfig.networkNameMapped)")
                        self.logger.info("[DEBUG] initializer: \(initializer)")
                        let result = try await initializer.initialize(config: adNetworkConfig)
                        logger.info("Successfully initialized network: \(adNetworkConfig.networkNameMapped) with result: \(result)")
                    } catch {
                        self.logger.error("[DEBUG] Failed to initialize network: \(adNetworkConfig.networkNameMapped) with error: \(error)")
                    }
                }
        
        var metricsEndpointURL = "https://ads.cloudx.io/metrics?a=test"
        
        self.reportingService = LiveAdEventReporter(endpoint: sdkConfig!.eventTrackingURL ?? metricsEndpointURL)
        
        if let endpointURL = self.sdkConfig?.metricsEndpointURL {
            metricsEndpointURL = endpointURL
        }

        var auctionEndpointUrl = "https://au-dev.cloudx.io/openrtb2/auction"
        var cdpEndpointUrl = ""
        
        if let auctionUrl = self.sdkConfig?.auctionEndpointURL.endpointString {
            auctionEndpointUrl = auctionUrl
        } else if let auctionUrl = self.sdkConfig?.auctionEndpointURL.endpointObject {
            auctionEndpointUrl = chooseEndpoint(object: auctionUrl, value: abTestValue)
        }

        cdpEndpointUrl = chooseEndpoint(object: self.sdkConfig?.cdpEndpointURL, value: 1 - abTestValue)
        
        self.logger.debug("=========================")
        self.logger.debug("choosenAuctionEndpoint: \(auctionEndpointUrl)")
        self.logger.debug("choosenCDPEndpoint: \(cdpEndpointUrl)")
        self.logger.debug("=========================")
        
        CloudX.shared.logsData["endpointData"] = "choosenAuctionEndpoint: \(auctionEndpointUrl) ||| choosenCDPEndpoint: \(cdpEndpointUrl)"
        
        DIContainer.shared.register(type: AppSessionService.self, AppSessionServiceImplementation(sessionID: self.sdkConfig!.sessionID ?? "", appKey: appKey, url: metricsEndpointURL))
        DIContainer.shared.register(type: BidNetworkService.self, BidNetworkServiceClass(auctionEndpointUrl: auctionEndpointUrl, cdpEndpointUrl: cdpEndpointUrl))
        _ = DIContainer.shared.resolve(.singleton, AppSessionService.self)
        if adNetworkFactories?.isEmpty == true {
            self.logger.debug("WARNING: CloudX SDK was not initialized with any adapters. At least one adapter is required to show ads.")
        } else {
            self.logger.debug("CloudX SDK initialised")
        }
        return true
    }
    
    
    /// Initialise the SDK to start serving ads
    /// - Parameters:
    ///   - appKey: The app key provided by CloudX
    ///   - completion: A completion handler that will be called once the SDK is initialised
    public func initSDK(appKey: String, completion: ((Bool, CloudXError?) -> Void)?) {
        Task {
            do {
                let result = try await initSDK(appKey: appKey)
                completion?(result, nil)
            } catch {
                self.logger.error("[DEBUG] Failed to init SDK: \(error)")
                completion?(false, error as? CloudXError)
            }
        }
    }
    
    private func resolveAdapters() {
        let adapterResolver = AdapterFactoryResolver()
        adNetworkFactories = adapterResolver.resolveAdNetworkFactories()
    }
    
    private func chooseEndpoint(object: SDKConfig.Response.EndpointObject?, value: Double) -> String {
        var stringToReturn = object?.defaultKey ?? defaultAuctionURL
        
        if let tests = object?.test {
            for test in tests {
                if value <= test.ratio {
                    stringToReturn = object?.defaultKey ?? ""
                } else {
                    stringToReturn = test.value
                    abTestName = test.name ?? ""
                }
            }
        }
        return stringToReturn
    }
    
    
    
    // TODO. Move this filter thing to xxxxAdapterFactory.canCreateAd(adNetwork: AdNetwork)
    private func filterConfig() {
        self.adPlacements = self.sdkConfig?.placements.associateBy { $0.name }
    }
    
    /// Create a banner ad
    /// - Parameters:
    ///   - placement: The placement name. This should match the placement name in the CloudX dashboard
    ///   - viewController: The view controller in which the ad will be displayed
    ///   - delegate: The delegate to receive ad events
    /// - Returns: A `CloudXBannerAdView` object
    @objc public func createBanner(placement: String, viewController: UIViewController, delegate: CloudXBannerDelegate? = nil) -> CloudXBannerAdView? {
        self.logger.debug("Creating banner for placement: \(placement)")
        let impModel = ConfigImpressionModel(
            sessionID: sdkConfig?.sessionID ?? "",
            auctionID: sdkConfig?.id ?? "",
            impressionTrackerURL: sdkConfig?.impressionTrackerURL ?? "",
            organizationID: sdkConfig?.organizationID ?? "",
            accountID: sdkConfig?.accountID ?? "",
            sdkConfig: sdkConfig,
            testGroupName: abTestName)
        let banner = adFactory.createBanner(
            viewController: viewController,
            placement: self.adPlacements?[placement],
            impModel: impModel,
            apiKey: self.appKey!,
            userID: self.userID ?? "",
            publisherID: "",
            type: .w320h50,
            bannerFactories: { self.adNetworkFactories?.banners },
            bidTokenSource: { self.adNetworkFactories?.bidTokenSources },
            reportingService: { self.reportingService! })
        
        return CloudXBannerAdView(banner: banner, type: .w320h50, delegate: delegate)
    }
    
    /// Create a MREC ad
    /// - Parameters:
    ///   - placement: The placement name. This should match the placement name in the CloudX dashboard
    ///   - viewController: The view controller in which the ad will be displayed
    ///   - delegate: The delegate to receive ad events
    /// - Returns: A `CloudXBannerAdView` object
    @objc public func createMREC(placement: String, viewController: UIViewController, delegate: CloudXBannerDelegate? = nil) -> CloudXBannerAdView? {
        self.logger.debug("Creating MREC for placement: \(placement)")
        let impModel = ConfigImpressionModel(
            sessionID: sdkConfig?.sessionID ?? "",
            auctionID: sdkConfig?.id ?? "",
            impressionTrackerURL: sdkConfig?.impressionTrackerURL ?? "",
            organizationID: sdkConfig?.organizationID ?? "",
            accountID: sdkConfig?.accountID ?? "",
            sdkConfig: sdkConfig,
            testGroupName: abTestName)
        let banner = adFactory.createBanner(
            viewController: viewController,
            placement: self.adPlacements?[placement],
            impModel: impModel,
            apiKey: self.appKey!,
            userID: self.userID ?? "",
            publisherID: "",
            type: .mrec,
            bannerFactories: { self.adNetworkFactories?.banners }, 
            bidTokenSource: { self.adNetworkFactories?.bidTokenSources },
            reportingService: { self.reportingService! })
        
        return CloudXBannerAdView(banner: banner, type: .mrec, delegate: delegate)
    }
    
    /// Create an interstitial ad
    /// - Parameters:
    ///   - placement: The placement name. This should match the placement name in the CloudX dashboard
    ///   - delegate: The delegate to receive ad events
    /// - Returns: A `CloudXInterstitial` object
    @objc public func createInterstitial(placement: String, delegate: CloudXInterstitialDelegate? = nil) -> CloudXInterstitial? {
        self.logger.debug("Creating interstitial for placement: \(placement)")
        return adFactory.createNewInterstitial(
            placement: self.adPlacements?[placement],
            delegate: delegate,
            userID: "",
            publisherID: "",
            interstitialFactories: self.adNetworkFactories,
            bidTokenSources: nil, //self.adNetworkFactories?.bidTokenSources
            cacheSize: 5,
            reportingService: self.reportingService!)
    }
    
    /// Create a rewarded ad
    /// - Parameters:
    ///   - placement: The placement name. This should match the placement name in the CloudX dashboard
    ///   - delegate: The delegate to receive ad events
    /// - Returns: A `CloudXRewardedInterstitial` object
    public func createRewarded(placement: String, delegate: CloudXRewardedDelegate? = nil) -> CloudXRewardedInterstitial? {
        self.logger.debug("Creating rewarded for placement: \(placement)")
        
        // Check if SDK is initialized
        guard isInitialised else {
            self.logger.error("Failed to create rewarded ad: SDK not initialized")
            return nil
        }
        
        // Check if placement exists
        guard let placementConfig = self.adPlacements?[placement] else {
            self.logger.error("Failed to create rewarded ad: Placement '\(placement)' not found in configuration")
            return nil
        }
        
        // Check if factories are available
        guard let factories = self.adNetworkFactories else {
            self.logger.error("Failed to create rewarded ad: No ad network factories available")
            return nil
        }
        
        // Check if reporting service is available
        guard let reporting = self.reportingService else {
            self.logger.error("Failed to create rewarded ad: No reporting service available")
            return nil
        }
        
        self.logger.debug("Creating rewarded ad with config: placement=\(placement), delegate=\(delegate != nil ? "present" : "nil")")
        
        let rewarded = adFactory.createNewRewarded(
            placement: placementConfig,
            delegate: delegate,
            userID: "",
            publisherID: "",
            rewardedFactories: self.adNetworkFactories,
            bidTokenSources: nil,
            cacheSize: 5,
            reportingService: reporting)
            
        if rewarded == nil {
            self.logger.error("Failed to create rewarded ad: Factory returned nil")
        } else {
            self.logger.debug("Successfully created rewarded ad instance")
        }
        
        return rewarded
    }
    
    /// Create a native ad
    /// - Parameters:
    ///   - placement: The placement name. This should match the placement name in the CloudX dashboard
    ///   - viewController: The view controller in which the ad will be displayed
    ///   - delegate: The delegate to receive ad events
    /// - Returns: A `CloudXNativeAdView` object
    @objc public func createNativeAd(placement: String, viewController: UIViewController, delegate: CloudXNativeDelegate?) -> CloudXNativeAdView? {
        let placement = self.adPlacements?[placement]
        var type: CloudXNativeTemplate = placement?.nativeTemplate ?? .small
        if type == .small && placement?.hasCloseButton ?? false {
            type = .smallWithCloseButton
        } else if type == .medium && placement?.hasCloseButton ?? false {
            type = .mediumWithCloseButton
        }
        
        self.logger.debug("Creating native for placement: \(String(describing: placement))")
        let native = adFactory.createNative(
            viewController: viewController,
            placement: placement,
            apiKey: self.appKey!,
            userID: self.userID ?? "",
            publisherID: "",
            type: type,
            nativeFactories: { self.adNetworkFactories?.native },
            reportingService: { self.reportingService! })
        
        guard let native = native else { return nil }
        return CloudXNativeAdView(native: native, type: type, delegate: delegate)
    }
    
    // Add or update this method to always return the bridge for ObjC
    @objc public func createRewardedWithPlacement(_ placement: String, delegate: CloudXRewardedDelegate? = nil) -> CloudXRewardedObjCBridge? {
        print("[CloudX] Creating rewarded ad for placement: \(placement)")
        guard let rewarded = createRewarded(placement: placement, delegate: delegate) else {
            print("[CloudX] Failed to create rewarded ad")
            return nil
        }
        print("[CloudX] Successfully created rewarded ad instance: \(type(of: rewarded))")
        return CloudXRewardedObjCBridge.getOrCreateInstance(for: rewarded, placement: placement)
    }
    
}

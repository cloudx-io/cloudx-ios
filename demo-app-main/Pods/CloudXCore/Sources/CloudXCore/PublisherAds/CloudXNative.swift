//
//  CloudXNative.swift
//  CloudXCore
//
//  Created by bkorda on 08.03.2024.
//

import UIKit

protocol CloudXNative: CloudXAd {
    var suspendPreloadWhenInvisible: Bool { get set }
    var delegate: AdapterNativeDelegate? { get set }
    var nativeType: CloudXNativeTemplate { get }
}

class PublisherNative: CloudXNative {
    var isAdLoaded: Bool {
        isReady
    }
    
    var suspendPreloadWhenInvisible: Bool
    var delegate: AdapterNativeDelegate?
    let nativeType: CloudXNativeTemplate
    var isReady: Bool = false
    
    private var bidAdSource: BidAdSource?
    private let adFactories: [SDKConfig.KnownAdapterName : AdapterNativeFactory]
    weak private var viewController: UIViewController?
    private var isLoading: Bool = false
    private var lastBidResponse: BidAdSourceResponse?
    private var currentLoadingNative: AdapterNative?
    private var previousNative: AdapterNative?
    private var nativeOnScreen: AdapterNative?
    private let refreshSeconds: Double
    private let timerService: BannerTimerService = BannerTimerService()
    private var waterfallBackoffAlgorithm: ExponentialBackoffStrategy
    private let placementID: String
    private let reportingService: AdEventReporting
    private var requestNativeTask: Task<Void, Error>?
    private let logger = Logger(category: "CloudXNative")
    private var forceStop: Bool = false
    private var successWin: Bool = false
    private var loadNativeTimesCount = 0
    private let placement: SDKConfig.Response.Placement
    
    private var adLoadStartTime: Date?
    
    @Service(.singleton) private var appSessionService: AppSessionService
    
    init(viewController: UIViewController,
         placement: SDKConfig.Response.Placement,
         userID: String?,
         publisherID: String,
         suspendPreloadWhenInvisible: Bool,
         delegate: AdapterNativeDelegate? = nil,
         nativeType: CloudXNativeTemplate,
         waterfallMaxBackOffTime: TimeInterval?,
         adFactories: [SDKConfig.KnownAdapterName : AdapterNativeFactory],
         bidTokenSources: [SDKConfig.KnownAdapterName : BidTokenSource],
         bidRequestTimeout: TimeInterval,
         reportingService: AdEventReporting
    ) {
        self.suspendPreloadWhenInvisible = suspendPreloadWhenInvisible
        self.delegate = delegate
        self.nativeType = nativeType
        self.adFactories = adFactories
        self.viewController = viewController
        self.refreshSeconds = 900
        self.placementID = placement.id
        self.reportingService = reportingService
        
        self.placement = placement
        
        self.waterfallBackoffAlgorithm = ExponentialBackoffStrategy(maxDelay: waterfallMaxBackOffTime ?? maxBackOffDelayDefault)
        
        //native template?
        self.bidAdSource = BidAdSource(userID: userID, placementID: placementID, dealID: placement.dealId, hasCloseButton: placement.hasCloseButton ?? false, publisherID: publisherID, adType: .native, bidTokenSources: bidTokenSources, nativeAdRequirements: nativeType.nativeAdRequirements, createBidAd: self.createNativeInstance)
    }
    
    func load() {
        if isLoading {
            return
        }
        isLoading = true
        Task { @MainActor in
            self.requestNativeUpdate()
        }
    }
    
    func destroy() {
        currentLoadingNative?.destroy()
        currentLoadingNative = nil
        nativeOnScreen?.destroy()
        nativeOnScreen = nil
        previousNative?.destroy()
        previousNative = nil
        requestNativeTask?.cancel()
        timerService.stop()
        self.isLoading = false
        self.forceStop = true
        self.loadNativeTimesCount = 0
    }
    
    func requestNativeUpdate() {
        guard !forceStop else { return }
        Task {
            defer { self.continueNativeChain() }
            do {
                logger.debug("call auction api for a new native ad")
                let storedImpressionId = LineItemConditionService.checkPlacementConditions(placement, placementIndex: self.loadNativeTimesCount)
                self.lastBidResponse = try await self.bidAdSource?.requestBid(adUnitID: placementID, storedImpressionId: storedImpressionId, successWin: successWin)
                let delay = self.waterfallBackoffAlgorithm.reset()
                self.loadNativeTimesCount += 1
                logger.debug("received bid id \(self.lastBidResponse!.bidID)")
                print("self.loadNativeTimesCount \(self.loadNativeTimesCount)")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                let delay = (try? self.waterfallBackoffAlgorithm.nextDelay()) ?? 1
                self.lastBidResponse = nil
                logger.debug("fail to received bid \(error)")
                logger.debug("sleep for \(delay) seconds")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    private func continueNativeChain() {
        guard !forceStop else { return }
        //try to load bid
        Task { @MainActor in
            if let bidItem = self.lastBidResponse?.createBidAd() as? AdapterNative {
                logger.debug("Loading native...")
                self.loadAdItem(bidItem)
            } else {
                if isLoading {
                    self.requestNativeUpdate()
                }
            }
        }
    }
    
    @MainActor
    private func createNativeInstance(adId: String, bidId: String, adm: String, adapterExtras: [String: String], burl: String?, hasClosedButton: Bool, network: SDKConfig.KnownAdapterName) -> AdapterNative? {
        guard let factory = adFactories[network],
              let viewController = viewController,
              let creativeNative = factory.create(viewController: viewController, type: self.nativeType, adId: adId, bidId: bidId, adm: adm, extras: adapterExtras, delegate: self)
        else {
            return nil
        }
        
        return creativeNative
    }
    
    
    private func timerDidReachEnd() {
        DispatchQueue.main.async {
            self.previousNative = self.currentLoadingNative
            self.requestNativeUpdate()
        }
    }
    
    private func loadAdItem(_ item: AdapterNative) {
        //need 1 second delay to prevent spamming request when no fill
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            item.timeout = false
            self.currentLoadingNative = item
            self.adLoadStartTime = Date()
            item.load()
        }
    }
    
}

extension PublisherNative: AdapterNativeDelegate {
    
    func close(native: any AdapterNative) {
        logger.debug("Native clicked")
        native.destroy()
        loadNativeTimesCount = 0
        delegate?.close(native: native)
    }
    
    
    func didLoad(native: AdapterNative) {
        if native.timeout {
            native.destroy()
            return
        }
        
        logger.debug("Native did load \(placementID)")
        let latency = Date().timeIntervalSince(self.adLoadStartTime!).milliseconds
        appSessionService.adLoaded(placementID: placementID, latency: latency)
        self.previousNative?.delegate = nil
        self.previousNative?.destroy()
        self.previousNative?.nativeView?.removeFromSuperview()
        
        self.nativeOnScreen = self.currentLoadingNative
        self.successWin = true
        
        reportingService.win(bidID: lastBidResponse!.bidID)
        //        self.lastBidResponse = nil
        
        delegate?.didLoad(native: native)
        
        self.timerService.startCountDown(deadline: refreshSeconds, completion: self.timerDidReachEnd)
    }
    
    func failToLoad(native: AdapterNative?, error: Error?) {
        logger.error("Native fail to load \(String(describing: error?.localizedDescription))")
        appSessionService.adFailedToLoad(placementID: placementID)
        if native?.timeout == true {
            native?.destroy()
            return
        }
        
        native?.destroy()
        lastBidResponse = nil
        self.successWin = false
        
        let delay = (try? self.waterfallBackoffAlgorithm.nextDelay()) ?? 1
        if delay == 0 {
            Task { @MainActor in
                self.requestNativeUpdate()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay){
                self.requestNativeUpdate()
            }
        }
        delegate?.failToLoad(native: native, error: CloudXError.noAdsLoaded)
    }
    
    func didShow(native: AdapterNative) {
        delegate?.didShow(native: native)
    }
    
    func impression(native: AdapterNative) {
        logger.debug("Native impression \(placementID)")
        reportingService.impression(bidID: lastBidResponse!.bidID)
        appSessionService.addSpend(placementID: placementID, spend: lastBidResponse!.price)
        appSessionService.addImpression(placementID: placementID)
        self.delegate?.impression(native: native)
    }
    
    func click(native: AdapterNative) {
        logger.debug("Native clicked")
        appSessionService.addClick(placementID: placementID)
        delegate?.click(native: native)
    }
    
    
}

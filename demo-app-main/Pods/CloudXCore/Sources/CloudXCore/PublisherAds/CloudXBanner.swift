//
//  CloudXBanner.swift
//  CloudXCore
//
//  Created by bkorda on 08.02.2024.
//

import UIKit

protocol CloudXBanner: CloudXAd {
    var suspendPreloadWhenInvisible: Bool { get set }
    var delegate: AdapterBannerDelegate? { get set }
    var bannerType: CloudXBannerType { get }
}

class PublisherBanner: CloudXBanner {
    var isAdLoaded: Bool {
        isReady
    }
    
    var suspendPreloadWhenInvisible: Bool
    var delegate: AdapterBannerDelegate?
    let bannerType: CloudXBannerType
    var isReady: Bool = false
    
    private var bidAdSource: BidAdSource?
    private let adFactories: [SDKConfig.KnownAdapterName : AdapterBannerFactory]
    weak private var viewController: UIViewController?
    private var isLoading: Bool = false
    private var lastBidResponse: BidAdSourceResponse?
    private var currentLoadingBanner: AdapterBanner?
    private var previousBanner: AdapterBanner?
    private var bannerOnScreen: AdapterBanner?
    private let refreshSeconds: Double
    private let timerService: BannerTimerService = BannerTimerService()
    private var waterfallBackoffAlgorithm: ExponentialBackoffStrategy
    private let placementID: String
    private let dealID: String?
    private let reportingService: AdEventReporting
    private var requestBannerTask: Task<Void, Error>?
    private let logger = Logger(category: "CloudXBanner")
    private var forceStop: Bool = false
    private var successWin: Bool = false
    private var loadBannerTimesCount = 0
    private let placementSuffix: String
    private let impressionIndexStart: Int
    private let impressionIndexEnd: Int
    private let placement: SDKConfig.Response.Placement
    private let impModel: ConfigImpressionModel
    
    private var adLoadStartTime: Date?
    private var encodedString: String = ""
    @Service(.singleton) private var appSessionService: AppSessionService
    
    init(viewController: UIViewController,
         placement: SDKConfig.Response.Placement,
         userID: String?,
         publisherID: String,
         suspendPreloadWhenInvisible: Bool,
         delegate: AdapterBannerDelegate? = nil,
         bannerType: CloudXBannerType,
         waterfallMaxBackOffTime: TimeInterval?,
         impModel: ConfigImpressionModel,
         adFactories: [SDKConfig.KnownAdapterName : AdapterBannerFactory],
         bidTokenSources: [SDKConfig.KnownAdapterName : BidTokenSource],
         bidRequestTimeout: TimeInterval,
         reportingService: AdEventReporting
    ) {
        self.suspendPreloadWhenInvisible = suspendPreloadWhenInvisible
        self.delegate = delegate
        self.bannerType = bannerType
        self.adFactories = adFactories
        self.viewController = viewController
        self.refreshSeconds = Double((placement.bannerRefreshRateMs ?? 10000) / 1000)
        self.placementID = placement.id
        self.dealID = placement.dealId
        self.reportingService = reportingService
        
        self.impModel = impModel
        
        self.placement = placement
        self.placementSuffix = placement.firstImpressionPlacementSuffix ?? ""
        self.impressionIndexStart = placement.firstImpressionLoopIndexStart ?? 0
        self.impressionIndexEnd = placement.firstImpressionLoopIndexEnd ?? 0
        
        self.waterfallBackoffAlgorithm = ExponentialBackoffStrategy(maxDelay: waterfallMaxBackOffTime ?? maxBackOffDelayDefault)
        
        let hasCloseButton = placement.hasCloseButton ?? false
        
        let adType: AdType = bannerType == .w320h50 ? .banner : .mrec
        self.bidAdSource = BidAdSource(userID: userID, placementID: placementID, dealID: dealID, hasCloseButton: hasCloseButton, publisherID: publisherID, adType: adType, bidTokenSources: bidTokenSources, nativeAdRequirements: nil, createBidAd: { @MainActor [weak self] adId,bidId,adm,adapterExtras,burl,hasClosedButton,network  in return self?.createBannerInstance(adId: adId, bidId: bidId, adm: adm, adapterExtras: adapterExtras, burl: burl, hasClosedButton: hasClosedButton, network: network) })
    }
    
    func load() {
        if isLoading {
            logger.debug("Banner load already in progress for placement: \(placementID)")
            return
        }
        logger.debug("Starting banner load process for placement: \(placementID)")
        isLoading = true
        Task { @MainActor in
            logger.debug("Requesting banner update for placement: \(placementID)")
            self.requestBannerUpdate()
        }
    }
    
    func destroy() {
        currentLoadingBanner?.destroy()
        currentLoadingBanner = nil
        bannerOnScreen?.destroy()
        bannerOnScreen = nil
        previousBanner?.destroy()
        previousBanner = nil
        requestBannerTask?.cancel()
        timerService.stop()
        self.isLoading = false
        self.forceStop = true
        self.bidAdSource = nil
        self.loadBannerTimesCount = 0
    }
    
    func requestBannerUpdate() {
        guard !forceStop else { return }
        Task {
            defer { self.continueBannerChain() }
            do {
                logger.debug("Sending loop-index: \(self.loadBannerTimesCount) for adId: \(placementID)")
                CloudX.shared.logsData["loopData"] = "loop-index: \(self.loadBannerTimesCount)"
                let storedImpressionId = LineItemConditionService.checkPlacementConditions(placement, placementIndex: self.loadBannerTimesCount)
                updateBidRequestWithLoopIndex()
                self.lastBidResponse = try await self.bidAdSource?.requestBid(adUnitID: placementID, storedImpressionId: storedImpressionId, successWin: successWin)
                let delay = self.waterfallBackoffAlgorithm.reset()
                self.loadBannerTimesCount += 1
                if let bidResponse = lastBidResponse {
                    let rillModel = RillImpressionModel(lastBidResponse: bidResponse, impModel: impModel, adapterName: bidResponse.networkName, loadBannerTimesCount: loadBannerTimesCount, placementID: placementID)
                    let rillString = RillImpressionInitService.createDataString(with: rillModel)
                    CloudX.shared.logsData["impData"] = "To *\(impModel.impressionTrackerURL)* with: *\(rillString)*"
                    encodedString = rillString.encoded()
                }
                print("self.loadBannerTimesCount \(self.loadBannerTimesCount)")
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
    
    private func continueBannerChain() {
        guard !forceStop else { return }
        Task { @MainActor in
            logger.debug("Continuing banner chain for placement: \(placementID)")
            if let bidItem = self.lastBidResponse?.createBidAd() as? AdapterBanner {
                logger.debug("Successfully created banner from bid for placement: \(placementID)")
                self.loadAdItem(bidItem)
            } else {
                logger.debug("No valid banner created from bid for placement: \(placementID)")
                if isLoading {
                    logger.debug("Retrying banner request due to isLoading=true")
                    self.requestBannerUpdate()
                }
            }
        }
    }
    
    @MainActor
    private func createBannerInstance(adId: String, bidId: String, adm: String, adapterExtras: [String: String], burl: String?, hasClosedButton: Bool, network: SDKConfig.KnownAdapterName) -> AdapterBanner? {
        logger.debug("Creating banner instance - AdID: \(adId), BidID: \(bidId), Network: \(network)")
        logger.debug("[CloudX][Banner] Instantiating adapter with adm preview: \(adm.prefix(100))")
        logger.debug("[CloudX][Banner] Adapter extras: \(adapterExtras)")
        
        guard let factory = adFactories[network] else {
            logger.error("No factory found for network: \(network)")
            return nil
        }
        
        guard let viewController = viewController else {
            logger.error("No view controller available for banner creation")
            return nil
        }
        
        guard let creativeBanner = factory.create(
            viewController: viewController,
            type: self.bannerType,
            adId: adId,
            bidId: bidId,
            adm: adm,
            hasClosedButton: hasClosedButton,
            extras: adapterExtras,
            delegate: self
        ) else {
            logger.error("Factory failed to create banner for network: \(network)")
            return nil
        }
        
        logger.debug("Successfully created banner instance for network: \(network)")
        return creativeBanner
    }
    
    
    private func timerDidReachEnd() {
        DispatchQueue.main.async {
            self.previousBanner = self.currentLoadingBanner
            self.requestBannerUpdate()
        }
    }
    
    private func updateBidRequestWithLoopIndex() {
        if var userDict = UserDefaults.standard.dictionary(forKey: "userKeyValue") as? [String: String] {
            userDict["loop-index"] = "\(self.loadBannerTimesCount)"
            UserDefaults.standard.set(userDict, forKey: "userKeyValue")
            logger.debug("updated auction api call with loop-index: \(self.loadBannerTimesCount)")
        }
    }
    
    private func loadAdItem(_ item: AdapterBanner) {
        logger.debug("[CloudX][Banner] Instantiating AdapterBanner: \(String(describing: type(of: item)))")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            logger.debug("[CloudX][Banner] Calling load() on AdapterBanner: \(String(describing: type(of: item)))")
            item.timeout = false
            self.currentLoadingBanner = item
            self.adLoadStartTime = Date()
            item.load()
        }
    }
    
}

extension PublisherBanner: AdapterBannerDelegate {
    
    func didLoad(banner: AdapterBanner) {
        logger.debug("[CloudX][Banner] didLoad delegate called for placement: \(placementID)")
        logger.debug("Banner loaded successfully for placement: \(placementID)")
        if banner.timeout {
            logger.debug("[CloudX][Banner] Banner had timeout=true, destroying banner")
            banner.destroy()
            return
        }
        
        let latency = Date().timeIntervalSince(self.adLoadStartTime!).milliseconds
        logger.debug("Ad loaded with latency: \(latency)")
        appSessionService.adLoaded(placementID: placementID, latency: latency)
        
        self.previousBanner?.delegate = nil
        self.previousBanner?.destroy()
        self.previousBanner?.bannerView?.removeFromSuperview()
        
        self.bannerOnScreen = self.currentLoadingBanner
        self.successWin = true
        
        logger.debug("Banner did load")
        if let lastBid = lastBidResponse {
            logger.debug("[CloudX][Banner] Reporting win for bidID=\(lastBid.bidID)")
            reportingService.win(bidID: lastBid.bidID)
            reportingService.showBannerNUrlAction(price: lastBid.price, nUrl: lastBid.nurl)
        }
        delegate?.didLoad(banner: banner)
        
        self.timerService.startCountDown(deadline: refreshSeconds, completion: self.timerDidReachEnd)
    }
    
    func failToLoad(banner: AdapterBanner?, error: Error?) {
        logger.error("[CloudX][Banner] failToLoad delegate called for placement: \(placementID), error: \(error?.localizedDescription ?? "unknown")")
        appSessionService.adFailedToLoad(placementID: placementID)
        if let banner = banner, banner.timeout == true {
            logger.debug("[CloudX][Banner] Banner had timeout=true, destroying banner")
            banner.destroy()
            return
        }
        banner?.destroy()
        lastBidResponse = nil
        self.successWin = false
        let delay = (try? self.waterfallBackoffAlgorithm.nextDelay()) ?? 1
        if delay == 0 {
            Task { @MainActor in
                self.requestBannerUpdate()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay){
                self.requestBannerUpdate()
            }
        }
        delegate?.failToLoad(banner: banner, error: error)
    }
    
    func didShow(banner: AdapterBanner) {
        delegate?.didShow(banner: banner)
    }
    
    func impression(banner: AdapterBanner) {
        logger.debug("[CloudX][Banner] impression delegate called for placement: \(placementID)")
        if let lastBid = lastBidResponse {
            logger.debug("[CloudX][Banner] Reporting impression for bidID=\(lastBid.bidID)")
            appSessionService.addImpression(placementID: placementID)
            appSessionService.addSpend(placementID: placementID, spend: lastBid.price)
            reportingService.impression(bidID: lastBid.bidID)
            if !encodedString.isEmpty {
                reportingService.rillTracking(urlString: impModel.impressionTrackerURL, encodedString: encodedString)
            }
        }
        self.delegate?.impression(banner: banner)
    }
    
    func click(banner: AdapterBanner) {
        logger.debug("[CloudX][Banner] click delegate called for placement: \(placementID)")
        appSessionService.addClick(placementID: placementID)
        delegate?.click(banner: banner)
    }
    
    func closedByUserAction(banner: AdapterBanner) {
        logger.debug("[CloudX][Banner] closedByUserAction delegate called for placement: \(placementID)")
        self.loadBannerTimesCount = 0
        delegate?.closedByUserAction(banner: banner)
    }
    
}

//
//  CacheAdService.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import UIKit

final class CacheAdService: Destroyable {
    private let bidAdSource: BidAdSource?
    private let bidLoadTimeout: TimeInterval
    private var createCacheableAd: (Destroyable?) -> CacheableAd?
    private let reachabilityService: ReachabilityService?
    private let placement: SDKConfig.Response.Placement
    
    private var cachedQueue: CacheAdQueue
    
    private var showCount: Int = 0
    private var waterfallBackoffAlgorithm: ExponentialBackoffStrategy
    
    private var willResignActiveObserver: Any?
    private var didBecomeActiveNotification: Any?
    private let logger = Logger(category: "CacheAdService")
    private var winSuccess: Bool = false
    
    var hasAds: Bool {
        return cachedQueue.hasItems
    }
    
    var first: CacheableAd? {
        return cachedQueue.first
    }
    
    internal init(placement: SDKConfig.Response.Placement,
                  bidAdSource: BidAdSource?,
                  waterfallMaxBackOffTime: TimeInterval?,
                  cacheSize: Int,
                  bidLoadTimeout: TimeInterval,
                  reportingService: AdEventReporting,
                  createCacheableAd: @escaping (Destroyable?) -> CacheableAd?) {
        
        self.bidAdSource = bidAdSource
        self.placement = placement
        self.bidLoadTimeout = bidLoadTimeout
        self.createCacheableAd = createCacheableAd
        self.reachabilityService = ReachabilityService()
        self.waterfallBackoffAlgorithm = ExponentialBackoffStrategy(initialDelay: 1, maxDelay: waterfallMaxBackOffTime ?? maxBackOffDelayDefault)
        
        self.cachedQueue = CacheAdQueue(maxCapacity: cacheSize, reportingService: reportingService, placementID: placement.id)
        
        didBecomeActiveNotification = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] notification in
            self?.continueLoading()
        }
        
        willResignActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] notification in
            self?.suspendLoading()
        }
        
        startLoading()
    }
    
    deinit {
        if let didBecomeActiveNotification = didBecomeActiveNotification {
            NotificationCenter.default.removeObserver(didBecomeActiveNotification)
        }
        
        if let willResignActiveObserver = willResignActiveObserver {
            NotificationCenter.default.removeObserver(willResignActiveObserver)
        }
    }
    
    private func startLoading() {
        Task {
            self.logger.debug("Start filling fullscreen ad queue")
            while self.cachedQueue.isEnoughSpace {
                await loadQueueItem()
            }
        }
    }
    
    private func loadQueueItem() async {
        let delay: TimeInterval
        do {
            try await self.enqueueItem(successWin: winSuccess)
            delay = self.waterfallBackoffAlgorithm.reset()
            winSuccess = true
        } catch {
            winSuccess = false
            self.logger.debug("fail to received bid \(error)")
            delay = (try? self.waterfallBackoffAlgorithm.nextDelay()) ?? 0
        }
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    private func suspendLoading() {
        //TODO: pause queue loading
    }
    
    private func continueLoading() {
        //TODO: continues queue loading
    }
    
    private func enqueueItem(successWin: Bool) async throws {
        
        guard cachedQueue.isEnoughSpace else {
            throw CacheAdQueueError.queueIsOverflow
        }
        
        self.logger.debug("Making bid request for a new fullscreen ad")
        let storedImpressionId = LineItemConditionService.checkPlacementConditions(placement, placementIndex: 0)
        guard let bidAd = try await bidAdSource?.requestBid(adUnitID: self.placement.id, storedImpressionId: storedImpressionId, successWin: successWin),
              let cacheable = await self.createCacheableAd(bidAd.createBidAd())
        else { throw CacheAdQueueError.failToCreateAd }
        
        let decoratedAd = MetricDecorator(ad: cacheable, placement: placement.id, price: bidAd.price)
        self.logger.debug("Bid received \(bidAd.bidID)")
        try await self.cachedQueue.enqueueAd(price: bidAd.price,
                                             loadTimeout: self.bidLoadTimeout,
                                             bidID: bidAd.bidID,
                                             ad: decoratedAd)
    }
    
    func destroy() {
        cachedQueue.destroy()
    }
    
    func popAd() -> CacheableAd? {
        let ad = cachedQueue.popAd()
        startLoading()
        return ad
    }
    
    func adError(ad: Destroyable) {
        cachedQueue.remove(ad: ad as! CacheableAd)
        startLoading()
    }
}

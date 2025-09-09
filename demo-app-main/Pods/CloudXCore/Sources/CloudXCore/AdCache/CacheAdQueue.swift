//
//  CacheAdQueue.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import UIKit

infix operator ===

enum CacheAdQueueError: Error {
    case adIsNil
    case failToLoad
    case timeout
    case queueIsOverflow
    case failToCreateAd
}

protocol CacheableAd: Destroyable {
    var network: String { get }
    var impressionID: String { get set }
    func load(with timeout: TimeInterval) async throws
    func show(from: UIViewController)
}

private struct QueueItem: Comparable {
    var ad: CacheableAd
    
    let price: Double

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.price == rhs.price
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.price < rhs.price
    }
    
    // check if ad units are equals
    static func === (lhs: Self, rhs: CacheableAd) -> Bool {
        return lhs.ad.network == rhs.network
    }
}

class CacheAdQueue {
    var maxCapacity: Int
    private var reportingService: AdEventReporting
    
    var isEnoughSpace: Bool {
        return sortedQueue.count < maxCapacity
    }
    
    var isEmpty: Bool {
        return sortedQueue.isEmpty
    }
    
    private var latestFirstElement: QueueItem?
    private var sortedQueue: [QueueItem] = []
    
    var hasItems: Bool {
        return sortedQueue.count > 0
    }
    
    var first: CacheableAd? {
        return sortedQueue.first?.ad
    }
    
    private let adLoadOperationQueue = OperationQueue()
    private let logger = Logger(category: "CacheAdQueue")
    private let placementID: String
    @Service(.singleton) private var appSessionService: AppSessionService
    
    init(maxCapacity: Int, reportingService: AdEventReporting, placementID: String) {
        self.maxCapacity = maxCapacity
        self.reportingService = reportingService
        self.placementID = placementID
        self.adLoadOperationQueue.maxConcurrentOperationCount = 2
    }
    
    func enqueueAd(price: Double, loadTimeout: TimeInterval, bidID: String, ad: CacheableAd?) async throws {
        guard let ad = ad else {
            throw CacheAdQueueError.adIsNil
        }
        
        logger.debug("Loading ad adapter")
        try await loadOrDestroyAd(ad: ad, loadTimeout: loadTimeout)
        reportingService.win(bidID: bidID)
        self.addQueueItem(item: QueueItem(ad: ad, price: price))
    }
    
    private func loadOrDestroyAd(ad: CacheableAd, loadTimeout: TimeInterval) async throws {
        do {
            let startLoadTime = Date()
            logger.debug("Load add timeout - \(loadTimeout)")
            try await ad.load(with: loadTimeout)
            let latency = Date().timeIntervalSince(startLoadTime).milliseconds
            logger.debug("Load add with latency - \(latency)ms, placementID - \(placementID), queue isEnoughSpace - \(isEnoughSpace), hasItems - \(hasItems), first - \(String(describing: first))")
            appSessionService.adLoaded(placementID: placementID, latency: latency)
        } catch {
            logger.debug("Fail to load ad with placementID: \(placementID)")
            appSessionService.adFailedToLoad(placementID: placementID)
            ad.destroy()
            throw CacheAdQueueError.failToLoad
        }
    }
    
    private func addQueueItem(item: QueueItem) {
        if sortedQueue.isEmpty {
            latestFirstElement = item
        }
        logger.debug("Adapter ad loaded. Put it in queue")
        sortedQueue.append(item)
        sortedQueue.sort(by: >)
        
        logger.debug("Queue contains \(sortedQueue.count) item(s)")
    }

    private func removeQueueItem(item: QueueItem?) {
        guard let item = item,
              let index = sortedQueue.firstIndex(of: item)
        else { return }

        item.ad.destroy()
        sortedQueue.remove(at: index)
    }

    func popAd() -> CacheableAd? {
        if sortedQueue.isEmpty { return nil }
        let item = sortedQueue.removeFirst()
        logger.debug("pop ad from queue \(item)")
        logger.debug("Queue contains \(sortedQueue.count) item(s)")
        return item.ad
    }
    
    func remove(ad: CacheableAd) {
        if let ad = sortedQueue.first(where: {$0.ad.impressionID == ad.impressionID}) {
            self.removeQueueItem(item: ad)
        }
    }
    
}

extension CacheAdQueue: Destroyable {
    
    func destroy() {
        sortedQueue.forEach {
            $0.ad.destroy()
        }
        sortedQueue.removeAll()
    }
    
}

class MetricDecorator: CacheableAd {
    var network: String {
        return ad.network
    }
    
    var impressionID: String {
        get {
            return ad.impressionID
        }
        set {
            ad.impressionID = newValue
        }
    }
    
    let placement: String
    let price: Double
    
    private let ad: CacheableAd
    
    init(ad: CacheableAd, placement: String, price: Double) {
        self.ad = ad
        self.placement = placement
        self.price = price
    }
    
    func load(with timeout: TimeInterval) async throws {
        try await ad.load(with: timeout)
    }
    
    func show(from viewController: UIViewController) {
        ad.show(from: viewController)
    }
    
    func destroy() {
        ad.destroy()
    }
    
}

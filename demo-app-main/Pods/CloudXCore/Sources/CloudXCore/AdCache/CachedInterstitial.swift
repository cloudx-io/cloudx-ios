//
//  CachedRewarded.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import UIKit

class CachedRewarded: CacheableAd {
    var impressionID: String = ""
    
    weak var delegate: AdapterRewardedDelegate?
    private(set) var rewarded: AdapterRewarded
    private var viewController: UIViewController?
    
    private var completion: ((Bool) -> Void)?
    private var continuation: CheckedContinuation<Void, Error>?
    private var loadingTimer: Timer?
    
    var network: String {
        return rewarded.network
    }
    
    let bidID: String = ""
    
    init(rewarded: AdapterRewarded,
         delegate: AdapterRewardedDelegate) {
        self.rewarded = rewarded
        self.delegate = delegate
        self.rewarded.delegate = self
    }
    
    func load(with timeout: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            rewarded.load()
            loadingTimer = Timer(timeInterval: timeout, repeats: false) { _ in
                self.continuation?.resume(throwing: CacheAdQueueError.timeout)
            }
            
            RunLoop.main.add(loadingTimer!, forMode: .common)
        }
    }
    
    func show(from viewController: UIViewController) {
        self.viewController = viewController
        rewarded.show(from: viewController)
    }
    
    func destroy() {
        completion = nil
        continuation = nil
        rewarded.destroy()
    }
    
    var description: String {
        return "\(rewarded)"
    }
}

extension CachedRewarded: AdapterRewardedDelegate {
    internal func didLoad(rewarded: AdapterRewarded) {
        loadingTimer?.invalidate()
        continuation?.resume(returning: ())
        continuation = nil
        self.delegate?.didLoad(rewarded: self.rewarded)
    }
    
    internal func didFailToLoad(rewarded: AdapterRewarded, error: Error) {
        Logger(category: "of").debug("!!!didFailToLoad from Adapter!!!! ")
        loadingTimer?.invalidate()
        continuation?.resume(throwing: CacheAdQueueError.failToLoad)
        continuation = nil
        self.delegate?.didFailToLoad(rewarded: self.rewarded, error: error)
    }
    
    internal func didShow(rewarded: AdapterRewarded) {
        self.delegate?.didShow(rewarded: self.rewarded)
    }
    
    func didFailToShow(rewarded: AdapterRewarded, error: Error) {
        self.delegate?.didFailToShow(rewarded: self.rewarded, error: error)
    }
    
    internal func impression(rewarded: AdapterRewarded) {
        self.delegate?.impression(rewarded: self.rewarded)
    }
    
    internal func didClose(rewarded: AdapterRewarded) {
        self.delegate?.didClose(rewarded: self.rewarded)
    }
    
    internal func click(rewarded: AdapterRewarded) {
        self.delegate?.click(rewarded: self.rewarded)
    }
    
    internal func expired(rewarded: AdapterRewarded) {
        self.delegate?.expired(rewarded: self.rewarded)
    }
    
    func userReward(rewarded: AdapterRewarded) {
        self.delegate?.userReward(rewarded: self.rewarded)
    }
}

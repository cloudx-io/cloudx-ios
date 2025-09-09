//
//  CachedInterstitial.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import UIKit

class CachedInterstitial: CacheableAd {
    var impressionID: String = ""
    
    weak var delegate: AdapterInterstitialDelegate?
    private(set) var interstitial: AdapterInterstitial
    private var viewController: UIViewController?
    
    private var completion: ((Bool) -> Void)?
    private var continuation: CheckedContinuation<Void, Error>?
    var loadingTimer: Timer?
    
    var network: String {
        return interstitial.network
    }
    
    init(interstitial: AdapterInterstitial,
         delegate: AdapterInterstitialDelegate) {
        self.interstitial = interstitial
        self.delegate = delegate
        self.interstitial.delegate = self
    }
    
    func load(with timeout: TimeInterval) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            interstitial.load()
            loadingTimer = Timer(timeInterval: timeout, repeats: false) { _ in
                self.continuation?.resume(throwing: CacheAdQueueError.timeout)
            }
            
            RunLoop.main.add(loadingTimer!, forMode: .common)
        }
    }
    
    func show(from viewController: UIViewController) {
        self.viewController = viewController
        interstitial.show(from: viewController)
    }
    
    func destroy() {
        completion = nil
        continuation = nil
        interstitial.destroy()
    }
    
    var description: String {
        return "\(interstitial)"
    }
}

extension CachedInterstitial: AdapterInterstitialDelegate {
    internal func didLoad(interstitial: AdapterInterstitial) {
        loadingTimer?.invalidate()
        continuation?.resume(returning: ())
        continuation = nil
        self.delegate?.didLoad(interstitial: self.interstitial)
    }
    
    internal func didFailToLoad(interstitial: AdapterInterstitial, error: Error) {
        loadingTimer?.invalidate()
        continuation?.resume(throwing: CacheAdQueueError.failToLoad)
        continuation = nil
        self.delegate?.didFailToLoad(interstitial: self.interstitial, error: error)
    }
    
    internal func didShow(interstitial: AdapterInterstitial) {
        self.delegate?.didShow(interstitial: self.interstitial)
    }
    
    func didFailToShow(interstitial: AdapterInterstitial, error: Error) {
        delegate?.didFailToShow(interstitial: self.interstitial, error: error)
    }
    
    internal func impression(interstitial: AdapterInterstitial) {
        self.delegate?.impression(interstitial: self.interstitial)
    }
    
    internal func didClose(interstitial: AdapterInterstitial) {
        self.delegate?.didClose(interstitial: self.interstitial)
    }
    
    internal func click(interstitial: AdapterInterstitial) {
        self.delegate?.click(interstitial: self.interstitial)
    }
    
    internal func expired(interstitial: AdapterInterstitial) {
        self.delegate?.expired(interstitial: self.interstitial)
    }
}

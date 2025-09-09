//
//  InvalidBanner.swift
//  
//
//  Created by bkorda on 04.03.2024.
//

import UIKit

class InvalidBanner: CloudXBanner {
    var suspendPreloadWhenInvisible: Bool = true
    var isReady: Bool = false
    var isAdLoaded: Bool = false
    var error: CloudXError
    
    init(error: CloudXError) {
        self.error = error
    }
    
    var bannerType: CloudXBannerType {
        return .w320h50
    }
    
    weak var delegate: AdapterBannerDelegate?
        
    func load() {
        delegate?.failToLoad(banner: DummyBanner(), error: self.error)
    }

    func destroy() {}
}

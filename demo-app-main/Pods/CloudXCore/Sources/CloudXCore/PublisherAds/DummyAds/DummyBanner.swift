//
//  DummyBanner.swift
//  
//
//  Created by bkorda on 04.03.2024.
//

import UIKit

class DummyBanner: AdapterBanner {
    func load() {
        
    }
    
    
    var delegate: AdapterBannerDelegate?
    
    var timeout: Bool = false
    
    var bannerView: UIView?
    
    var sdkVersion: String = ""
    
    var isReady: Bool = false
    
    func destroy() {
        
    }
    
}

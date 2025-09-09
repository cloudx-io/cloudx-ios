//
//  CloudXTestVastNetworkBannerFactory.swift
//  
//
//  Created by bkorda on 06.04.2024.
//

import UIKit
import CloudXCore

final class CloudXTestVastNetworkNativeFactory: AdapterNativeFactory {
    
    func create(viewController: UIViewController, type: CloudXCore.CloudXNativeTemplate, adId: String, bidId: String, adm: String, extras: [String: String], delegate: CloudXCore.AdapterNativeDelegate) -> CloudXCore.AdapterNative? {
        //"/6499/example/native"
        return CloudXTestVastNetworkNative(adm: adm, type: type, viewController: viewController, delegate: delegate)
    }
    
    static func createInstance() -> CloudXTestVastNetworkNativeFactory {
        CloudXTestVastNetworkNativeFactory()
    }
    
}

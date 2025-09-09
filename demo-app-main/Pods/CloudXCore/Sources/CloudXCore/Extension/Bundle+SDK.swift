//
//  Bundle+SDK.swift
//  CloudXCore
//
//  Created by bkorda on 21.02.2024.
//

import Foundation

extension Bundle {
  var releaseVersionNumber: String {
    return infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
  }

  static var app: Bundle {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      return Bundle(identifier: "com.cloudx.sdk.core") ?? Bundle(for: CloudX.self)
    #endif
  }

  static var sdk: Bundle {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      let bundle = Bundle(for: CloudX.self)
      if let url = bundle.url(forResource: String(describing: CloudX.self), withExtension: "bundle"), let sdkBundle = Bundle(url: url) {
        return sdkBundle
      }

//      // When running from cocoapods source the resource bundles are located at <PROJECT_BUNDLENAME>.bundle
//      if let url = bundle.resourceURL?.appendingPathComponent("CloudX.bundle"), let sdkBundle = Bundle(url: url) {
//        return sdkBundle
//      }

      return bundle
    #endif
  }
}

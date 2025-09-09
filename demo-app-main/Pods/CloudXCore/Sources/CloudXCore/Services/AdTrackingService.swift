//
//  AdTrackingService.swift
//  CloudXCore
//
//  Created by Bohdan Korda on 08.02.2024.
//

import AdSupport
import AppTrackingTransparency
import Foundation

final class AdTrackingService {

  static var isIDFAAccessAllowed: Bool {
    if #available(iOS 14, *) {
      return ATTrackingManager.trackingAuthorizationStatus == .authorized
    } else {
      return ASIdentifierManager.shared().isAdvertisingTrackingEnabled
    }
  }

  static var idfa: String? {
    if #available(iOS 14, *) {
      return ATTrackingManager.trackingAuthorizationStatus == .authorized ? ASIdentifierManager.shared().advertisingIdentifier.uuidString : nil
    } else {
      return ASIdentifierManager.shared().isAdvertisingTrackingEnabled ? ASIdentifierManager.shared().advertisingIdentifier.uuidString : nil
    }
  }

  static var dnt: Bool {
    if #available(iOS 14, *) {
      return ATTrackingManager.trackingAuthorizationStatus != .authorized
    } else {
      return ASIdentifierManager.shared().isAdvertisingTrackingEnabled
    }
  }
}

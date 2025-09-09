//
//  Utils.swift
//  CloudXCore
//
//  Created by bkorda on 21.02.2024.
//

import AdSupport
import SystemConfiguration
import UIKit

enum DeviceType: Int {
  case phone = 4
  case tablet = 5
  case unknown = 1

  var stringValue: String {
    switch self {
    case .tablet:
      return "tablet"
    case .phone, .unknown:
      return "mobile"
    }
  }

  init(interfaceIdiom: UIUserInterfaceIdiom) {
    switch interfaceIdiom {
    case .pad:
      self = .tablet
    case .phone:
      self = .phone
    default:
      self = .unknown
    }
  }
}

protocol SystemInformationProtocol {
  var deviceType: DeviceType { get }
  var sdkVersion: String { get }
  var sdkBundle: String { get }

  var appBundleIdentifier: String { get }
  var appVersion: String { get }

  var osVersion: String { get }
  var idfa: String? { get }
  var idfv: String? { get }
  var dnt: Bool { get }
  var lat: Bool { get }
  
  var os: String { get }
  var model: String { get }
  var systemVersion: String { get }
  var hardwareVersion: String { get }
  var displayManager: String { get }
}

final class SystemInformation: SystemInformationProtocol {

  static var shared: SystemInformationProtocol = SystemInformation()
  
  var idfa: String? = AdTrackingService.idfa
  var dnt: Bool = AdTrackingService.dnt
  var lat: Bool = AdTrackingService.dnt
  var idfv: String? = UIDevice.current.identifierForVendor?.uuidString

  var deviceType = DeviceType(interfaceIdiom: UIDevice.current.userInterfaceIdiom)
  var sdkVersion: String = {
    if let bundle = Bundle(identifier: "com.cloudx.sdk.core"),
      let version = bundle.infoDictionary?["CloudXMarketingVersion"] as? String
    {
      return version
    } else if let url = Bundle.main.url(forResource: "CloudXSDK", withExtension: "bundle"),
      let bundle = Bundle(url: url),
      let version = bundle.infoDictionary?["CloudXMarketingVersion"] as? String
    {
      return version
    } else if let version = Bundle(for: CloudX.self).infoDictionary?["CloudXMarketingVersion"] as? String {
      return version
    }

    //marker that version was not read
    return "0.0.0"
  }()
  var sdkBundle = Bundle.sdk.bundleIdentifier ?? ""

  var appBundleIdentifier = Bundle.main.bundleIdentifier ?? ""
  var appVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

  var osVersion: String = UIDevice.current.systemVersion
  var os = "iOS"
  var model = UIDevice.deviceIdentifier
  var systemVersion = UIDevice.current.systemVersion
  var hardwareVersion = UIDevice.deviceGeneration
  var displayManager: String { "CLOUDX" }

}

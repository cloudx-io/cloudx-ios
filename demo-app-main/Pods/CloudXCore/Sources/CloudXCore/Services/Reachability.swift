//
//  Reachability.swift
//  CloudXCore
//
//  Created by bkorda on 21.02.2024.
//

import Combine
import CoreTelephony
import Foundation
import SystemConfiguration

private let reachabilityStatusChangedNotification = "ReachabilityStatusChangedNotification"
private let reachabilityStatusUserInfoKey = "status"

enum ReachabilityType: String {
  case unknown
  case wwan2g
  case wwan3g
  case wwan4g
  case wwan
  case wifi
}

enum ReachabilityStatus: CustomStringConvertible {
  case offline
  case online(ReachabilityType)
  case unknown

  var connectionType: ReachabilityType {
    switch self {
    case .online(let type):
      return type
    default:
      return .unknown
    }
  }

  var isOffline: Bool {
    switch self {
    case .offline:
      return true
    default:
      return false
    }
  }

  var description: String {
    switch self {
    case .offline:
      return "offline"
    case .online(let type):
      return type.rawValue
    case .unknown:
      return "unknown"
    }
  }
}

@available(iOS 13.0, *)
final class ReachabilityService {

  var reachabilityStatusPublisher: AnyPublisher<ReachabilityStatus, Never> {
    subject.eraseToAnyPublisher()
  }

  private var lastConnectionStatus: ReachabilityStatus = .unknown {
    didSet { subject.send(lastConnectionStatus) }
  }

  private let subject: PassthroughSubject<ReachabilityStatus, Never>

  init() {
    subject = PassthroughSubject()
    NotificationCenter.default.addObserver(
      self, selector: #selector(reachabilityStatusChanged), name: Notification.Name(rawValue: reachabilityStatusChangedNotification),
      object: nil)
    monitorReachabilityChanges()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func connectionStatus() -> ReachabilityStatus {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sin_family = sa_family_t(AF_INET)

    guard
      let defaultRouteReachability = withUnsafePointer(
        to: &zeroAddress,
        {
          $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            SCNetworkReachabilityCreateWithAddress(nil, $0)
          }
        })
    else {
      return .unknown
    }

    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
      return .unknown
    }

    let status = ReachabilityStatus(reachabilityFlags: flags)
    return status
  }

  func monitorReachabilityChanges() {
    let host = "google.com"
    var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
    let reachability = SCNetworkReachabilityCreateWithName(nil, host)!

    SCNetworkReachabilitySetCallback(
      reachability,
      { (_, flags, _) in
        let status = ReachabilityStatus(reachabilityFlags: flags)

        NotificationCenter.default.post(
          name: Notification.Name(rawValue: reachabilityStatusChangedNotification),
          object: nil,
          userInfo: [reachabilityStatusUserInfoKey: status])

      }, &context)

    SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), RunLoop.Mode.common as CFString)
  }

  @objc func reachabilityStatusChanged(notification: Notification) {
    lastConnectionStatus = notification.userInfo?[reachabilityStatusUserInfoKey] as? ReachabilityStatus ?? .unknown
  }

}

extension ReachabilityStatus {
  init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
    let connectionRequired = flags.contains(.connectionRequired)
    let isReachable = flags.contains(.reachable)
    let isWWAN = flags.contains(.isWWAN)

    if !connectionRequired && isReachable {
      if isWWAN {
        let networkInfo = CTTelephonyNetworkInfo()
        let carrierType = networkInfo.serviceCurrentRadioAccessTechnology?.values.first
        switch carrierType {
        case CTRadioAccessTechnologyGPRS,
          CTRadioAccessTechnologyEdge,
          CTRadioAccessTechnologyCDMA1x:
          self = .online(.wwan2g)
        case CTRadioAccessTechnologyWCDMA,
          CTRadioAccessTechnologyHSDPA,
          CTRadioAccessTechnologyHSUPA,
          CTRadioAccessTechnologyCDMAEVDORev0,
          CTRadioAccessTechnologyCDMAEVDORevA,
          CTRadioAccessTechnologyCDMAEVDORevB,
          CTRadioAccessTechnologyeHRPD:
          self = .online(.wwan3g)
        case CTRadioAccessTechnologyLTE?:
          self = .online(.wwan4g)
        default: self = .online(.wwan)
        }

      } else {
        self = .online(.wifi)
      }
    } else {
      self = .offline
    }
  }
}

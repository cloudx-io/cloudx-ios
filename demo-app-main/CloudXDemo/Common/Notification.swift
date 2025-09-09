//
//  Notification.swift
//  CloudXDemoTests
//
//  Created by bkorda on 29.03.2024.
//

import Foundation

extension Notification.Name {
    static func Name(_ name: String) -> Notification.Name {
        return Notification.Name("ad.cloudx.sdk.demo." + name)
    }
}

extension Notification.Name {
    static let mockSdkInit = Notification.Name("mock.sdkInit")
    static let mockBidFront = Notification.Name("mock.bidFront")
    static let mockServerStatus = Notification.Name("mock.serverStatus")
}

extension Notification {
    var isTrue:Bool {
        return userInfo?["value"] as? Bool ?? false
    }
}

extension NotificationCenter {

    func post(event: Notification.Name, value: Bool? = nil) {
        NotificationCenter.default.post(name: event, object: nil, userInfo: ["value": value ?? false])
    }

    func on(event: Notification.Name, callback: @escaping (Notification) -> Void) {
        NotificationCenter.default.addObserver(forName: event, object: nil, queue: OperationQueue.main) { notification in
            callback(notification)
        }
    }

}


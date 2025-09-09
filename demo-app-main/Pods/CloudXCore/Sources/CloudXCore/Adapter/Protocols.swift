//
//  Protocols.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import Foundation

/// Base protocol for adapter ad factories.
public protocol AdFactory {}

/// Implement this protocol to destroy ad.
@objc public protocol Destroyable {
    /// Destroys ad and release it from memory.
    func destroy()
}

/// Implement this protocol to check ad status.
@objc public protocol StatusCheck {
    /// Returns true if ad is ready to be shown.
    var isReady: Bool { get }
}

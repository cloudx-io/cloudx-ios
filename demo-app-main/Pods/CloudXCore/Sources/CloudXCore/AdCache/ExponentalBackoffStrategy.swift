//
//  WaterfallBackoffAlgorithm.swift
//
//
//  Created by bkorda on 06.03.2024.
//

import UIKit
import Foundation

/**
 * Algorithm to backoff retrying ad.load() when there have been a lot of adLoadFailed events.
 */

let maxBackOffDelayDefault: TimeInterval = 60

enum ExponentialBackoffStrategyError: Error {
    case maxAttemptsReached
}

struct ExponentialBackoffStrategy {
    private var maxAttempts: Int = 0
    private var attempt: Int = 0
    private let initialDelay: TimeInterval
    private let maxDelay: TimeInterval

    init(initialDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 60.0, maxAttempts: Int = .max) {
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.maxAttempts = maxAttempts
    }

    mutating func nextDelay() throws -> TimeInterval {
        if self.attempt >= self.maxAttempts {
            throw ExponentialBackoffStrategyError.maxAttemptsReached
        }
        
        //do first request without delay
        if attempt == 0 {
            self.attempt += 1
            return 0
        }
        
        let delay = min(self.initialDelay * pow(2.0, Double(self.attempt)), self.maxDelay)
        self.attempt += 1
        return delay
    }

    @discardableResult
    mutating func reset() -> TimeInterval {
        self.attempt = 0
        return 0
    }
}

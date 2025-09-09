//
//  SessionMetric.swift
//  CloudXCore
//
//  Created by bkorda on 02.05.2024.
//

import Foundation

enum SessionMetricType: String, Decodable {
    case spend
    case impression
    case fillRate = "fill_rate"
    case bidRequestLatency = "bid_request_success_avg_latency"
    case adLoadLatency = "ad_load_success_avg_latency"
    case adLoadFailCount = "ad_load_fail_count"
    case closeLatency = "ad_avg_time_to_close"
    case ctr
    case clickCount = "click_count"
}

protocol SessionMetric: Decodable {
//    var type: SessionMetricType { get }
//    var value: Double { get }
    var placementID: String { get }
}

struct SessionMetricSpend: SessionMetric {
    let placementID: String
    let type: SessionMetricType
    let value: Double
    let timestamp: Date
}

struct SessionMetricPerformance: SessionMetric {
    let placementID: String
    var adLoadCount: Int
    var adLoadLatency: Double
    var bidRequestLatency: Double
    var bidResponseCount: Int
    var clickCount: Int
    var closeCount: Int
    var closeLatency: Double
    var failToLoadAdCount: Int
    var impressionCount: Int
}

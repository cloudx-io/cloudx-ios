//
//  MetricsNetworkService.swift
//
//
//  Created by bkorda on 10.04.2024.
//

import Foundation

enum NetworkError: Error {
    case invalidRequest
}

final class MetricsNetworkService: BaseNetworkService {
    
    struct Request: Encodable, RequestParameters {
        var urlParams: [String : String] { [:] }
        func headers(token: String) -> HTTPHeaders? { ["Authorization" : "Bearer \(token)"] }
        
        let session: Session
        
        var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
            .custom({ (date, encoder) throws in
                var container = encoder.singleValueContainer()
                let seconds: UInt = UInt(date.timeIntervalSince1970)
                try container.encode(seconds)
            })
        }
        
        struct Session: Encodable {
            
            struct Metric: Encodable {
                
                enum CodingKeys: String, CodingKey {
                    case placementID
                    case type
                    case value
                    case timestamp
                    case meta = "by_placement_id"
                }
                
                let placementID: String?
                let type: String
                let value: Double?
                let timestamp: Date?
                var meta: [String : Double]?
                
                init(_ metric: SessionMetricSpend) {
                    self.placementID = metric.placementID
                    self.type = metric.type.rawValue
                    self.value = metric.value
                    self.timestamp = metric.timestamp
                    self.meta = nil
                }
                
                init(type: String, meta: [String : Double]) {
                    self.meta = meta
                    self.type = type
                    self.timestamp = nil
                    self.placementID = nil
                    self.value = nil
                }
            }
            
            let ID: String
            let duration: Int
            let metrics: [Metric]
        }
    }
    
    func trackEndSession(session: AppSessionModel) async throws {
        guard let id = session.id,
              let token = session.appKey
        else {
            throw NetworkError.invalidRequest
        }
        
        var metrics = session
            .metrics?
            .allObjects
            .compactMap { $0 as? SessionMetricModel }
            .compactMap { SessionMetricSpend($0) }
            .map { Request.Session.Metric($0) } ?? []
        
        if let performanceMetrics = session
            .performanceMetrics?
            .allObjects
            .compactMap { $0 as? PerformanceMetricModel } {
                
                var fillRateMetric = Request.Session.Metric(type: SessionMetricType.fillRate.rawValue, meta: [:])
                var ctrMetric = Request.Session.Metric(type: SessionMetricType.ctr.rawValue, meta: [:])
                var bidRequestLatencyMetric = Request.Session.Metric(type: SessionMetricType.bidRequestLatency.rawValue, meta: [:])
                var adLoadLatencyMetric = Request.Session.Metric(type: SessionMetricType.adLoadLatency.rawValue, meta: [:])
                var clickCountMetric = Request.Session.Metric(type: SessionMetricType.clickCount.rawValue, meta: [:])
                var failToLoadAdCountMetric = Request.Session.Metric(type: SessionMetricType.adLoadFailCount.rawValue, meta: [:])
                var closeLatencyMetric = Request.Session.Metric(type: SessionMetricType.closeLatency.rawValue, meta: [:])
                
                for metric in performanceMetrics {
                    //---------------
                    var fillrate: Double = 0
                    if metric.bidResponseCount != 0 {
                        fillrate = Double(metric.impressionCount) / Double(metric.bidResponseCount) * 100.0
                    }
                    
                    fillRateMetric.meta?[metric.placementID!] = fillrate
                    
                    print("Fillrate for \(metric.placementID): \(fillrate)")
                    //------------------
                    var ctr: Double = 0
                    if metric.impressionCount != 0 {
                        ctr = Double(metric.clickCount) / Double(metric.impressionCount) * 100.0
                    }
                    
                    ctrMetric.meta?[metric.placementID!] = ctr
                    print("CTR for \(metric.placementID): \(ctr)")
                    //--------------------
                    var bidRequestLatency: Double = 0
                    if metric.bidResponseCount != 0 {
                        bidRequestLatency = metric.bidRequestLatency / Double(metric.bidResponseCount)
                    }
                    bidRequestLatencyMetric.meta?[metric.placementID!] = bidRequestLatency
                    print("Bid request latency for \(metric.placementID): \(bidRequestLatency)")
                    //---------------------
                    var adLoadLatency: Double = 0
                    if metric.adLoadCount != 0 {
                        adLoadLatency = metric.adLoadLatency / Double(metric.adLoadCount)
                    }
                    adLoadLatencyMetric.meta?[metric.placementID!] = adLoadLatency
                    print("Ad load latency for \(metric.placementID): \(adLoadLatency)")
                    //---------------------
                    var clickCount = metric.clickCount
                    clickCountMetric.meta?[metric.placementID!] = Double(clickCount)
                    print("Click count for \(metric.placementID): \(clickCount)")
                    //---------------------
                    var failToLoadAdCount = metric.failToLoadAdCount
                    failToLoadAdCountMetric.meta?[metric.placementID!] = Double(failToLoadAdCount)
                    print("Fail to load ad count for \(metric.placementID): \(metric.failToLoadAdCount)")
                    //---------------------
                    var closeLatency: Double = 0
                    
                    if metric.closeCount != 0 {
                        closeLatency = metric.closeLatency / Double(metric.closeCount)
                    }
                    closeLatencyMetric.meta?[metric.placementID!] = closeLatency
                    print("Close latency for \(metric.placementID): \(closeLatency)")
                }
                
                var performanceMetrixRequest = [fillRateMetric, ctrMetric, bidRequestLatencyMetric, adLoadLatencyMetric, clickCountMetric, failToLoadAdCountMetric, closeLatencyMetric]
                
                metrics.append(contentsOf: performanceMetrixRequest)
            }
        
        let request = Request(session: .init(ID: id,
                                             duration: Int(session.duration),
                                             metrics: metrics))
        
        if let data = try? JSONSerialization.data(withJSONObject: request.json, options: .prettyPrinted),
            let jsonString = String(data: data, encoding: .utf8) {
              print(jsonString)
          }
        try await executeRequest(method: .post, endpoint: "", urlParameters: request.urlParams, requestBody: request.json, headers: request.headers(token: token), timeout: 3, maxRetries: 3, delay: 1)
    }
}

//
//  AppSession.swift
//
//
//  Created by bkorda on 05.03.2024.
//

import Foundation
import CoreData

protocol AppSessionMetric {
    func addSpend(placementID: String, spend: Double)
    func addImpression(placementID: String)
    func addClick(placementID: String)
    func addClose(placementID: String, latency: Double)
    func bidLoaded(placementID: String, latency: Double)
    func adLoaded(placementID: String, latency: Double)
    func adFailedToLoad(placementID: String)
}

class AppSession: AppSessionMetric, CustomStringConvertible {
    let sessionID: String
    let startDate: Date
    let url: URL
    let appKey: String

    private(set) var metrics: [SessionMetricSpend] = []
    private(set) var performanceMetrics: [SessionMetricPerformance] = []
    private(set) var sessionDuration: Double = 0
    private var sessionTimer: Timer?

    func addSpend(placementID: String, spend: Double) {
        let metric = SessionMetricSpend(placementID: placementID, type: .spend, value: spend, timestamp: Date())
        self.metrics.append(metric)
        CoreDataManager.shared.updateAppSession(with: self)
    }

    func addImpression(placementID: String) {
        CoreDataManager.shared.createOrGetPerformanceMetric(for: placementID, session: self) { metric in
            metric?.impressionCount += 1
            CoreDataManager.shared.saveContext()
        }
    }

    func addClick(placementID: String) {
        CoreDataManager.shared.createOrGetPerformanceMetric(for: placementID, session: self) { metric in
            metric?.clickCount += 1
            CoreDataManager.shared.saveContext()
        }
    }

    func adFailedToLoad(placementID: String) {
        CoreDataManager.shared.createOrGetPerformanceMetric(for: placementID, session: self) { metric in
            metric?.failToLoadAdCount += 1
            CoreDataManager.shared.saveContext()
        }
    }

    func bidLoaded(placementID: String, latency: Double) {
        CoreDataManager.shared.createOrGetPerformanceMetric(for: placementID, session: self) { metric in
            metric?.bidResponseCount += 1
            let currentLatency = metric?.bidRequestLatency ?? 0
            metric?.bidRequestLatency = currentLatency + latency
            CoreDataManager.shared.saveContext()
        }
    }

    func adLoaded(placementID: String, latency: Double) {
        CoreDataManager.shared.createOrGetPerformanceMetric(for: placementID, session: self) { metric in
            metric?.adLoadCount += 1
            let currentLatency = metric?.adLoadLatency ?? 0
            metric?.adLoadLatency = currentLatency + latency
            CoreDataManager.shared.saveContext()
        }
    }

    func addClose(placementID: String, latency: Double) {
        CoreDataManager.shared.createOrGetPerformanceMetric(for: placementID, session: self) { metric in
            metric?.closeCount += 1
            let currentLatency = metric?.closeLatency ?? 0
            metric?.closeLatency = currentLatency + latency
            CoreDataManager.shared.saveContext()
        }
    }

    init(sessionID: String, url: URL, appKey: String) {
        self.sessionID = sessionID
        self.startDate = Date()
        self.url = url
        self.appKey = appKey

        CoreDataManager.shared.createAppSession(with: self)
        sessionTimer = Timer(timeInterval: 5, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            let currentDate = Date()
            sessionDuration = currentDate.timeIntervalSince(self.startDate)
            CoreDataManager.shared.updateAppSession(with: self)
        }

        RunLoop.main.add(sessionTimer!, forMode: .common)
    }

    dynamic var description: String {
        return "SessionID: \(sessionID), StartDate: \(startDate), Metrics: \(metrics)"
    }
}

extension AppSession {

    convenience init?(model: AppSessionModel) {
        guard let id = model.id, let url = model.url, let appKey = model.appKey else {
            return nil
        }
        self.init(sessionID: id, url: url, appKey: appKey)

        metrics = model.metrics?.compactMap { SessionMetricSpend($0 as! SessionMetricModel) } ?? []
        sessionDuration = model.duration
    }

}

extension SessionMetricSpend {

    init?(_ model: SessionMetricModel) {
        guard let placementID = model.placementID,
              let typeStr = model.type,
              let type = SessionMetricType(rawValue: typeStr),
              let timestamp = model.timestamp else {
            return nil
        }
        self.init(placementID: placementID, type: type, value: model.value, timestamp: model.timestamp!)
    }

}


//extension SessionMetricPerformance {
//    init?(_ model: PerformanceMetricModel) {
//        guard let placementID = model.placementID,
//              let typeStr = model.,
//                let type = SessionMetricType(rawValue: typeStr),
//                let timestamp = model.timestamp else {
//            return nil
//        }
//        self.init(placementID: placementID, type: type, value: model.value, timestamp: model.timestamp!)
//    }
//}

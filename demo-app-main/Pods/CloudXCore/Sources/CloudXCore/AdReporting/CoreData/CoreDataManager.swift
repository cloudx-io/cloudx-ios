//
//  CoreDataManager.swift
//  CloudXCore
//
//  Created by bkorda on 10.04.2024.
//

import Foundation
import CoreData

final class CoreDataManager {

    private let logger = Logger(category: "CoreDataManager")
    private let entityName: String = String(describing: AppSessionModel.self)
    static let shared = CoreDataManager()

    private init() {}

    lazy public var persistentContainer: NSPersistentContainer? = {
        guard let modelURL = Bundle.sdk.url(forResource: "CloudXDataModel", withExtension: "momd") else { return nil }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else { return nil }
        let container = NSPersistentContainer(name: "CloudXMetricsContainer", managedObjectModel: model)
        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                self?.logger.error("Unresolved error \(error), \(error.userInfo)")
            }
        })

        self.logger.debug("local database is in \(container.persistentStoreCoordinator.persistentStores)")
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer!.viewContext
    }

    func saveContext() {
        viewContext.perform {
            guard self.viewContext.hasChanges else { return }
            do {
                try self.viewContext.save()
            } catch {
                self.logger.error("Unable to save context: \(error)")
            }
        }
    }

    func fetch<T: NSManagedObject>(_ type: T.Type) -> [T] {
        var results: [T] = []
        viewContext.performAndWait {
            let request = NSFetchRequest<T>(entityName: String(describing: type))
            do {
                results = try self.viewContext.fetch(request)
            } catch {
                self.logger.error("Unable to fetch entities: \(error)")
            }
        }
        return results
    }

    func fetchAppSession(sessionID: String) -> AppSessionModel? {
        var result: AppSessionModel?
        viewContext.performAndWait {
            let request = NSFetchRequest<AppSessionModel>(entityName: entityName)
            request.predicate = NSPredicate(format: "id == %@", sessionID)
            do {
                result = try self.viewContext.fetch(request).first
            } catch {
                self.logger.error("Unable to fetch entities: \(error)")
            }
        }
        return result
    }

    func fetchSessionMetric(timestamp: Date) -> SessionMetricModel? {
        var result: SessionMetricModel?
        viewContext.performAndWait {
            let request = NSFetchRequest<SessionMetricModel>(entityName: String(describing: SessionMetricModel.self))
            request.predicate = NSPredicate(format: "timestamp == %@", timestamp as CVarArg)
            do {
                result = try self.viewContext.fetch(request).first
            } catch {
                self.logger.error("Unable to fetch entities: \(error)")
            }
        }
        return result
    }

    func createAppSession(with session: AppSession) {
        viewContext.perform {
            let appSession = AppSessionModel(context: self.viewContext)
            appSession.url = session.url
            appSession.appKey = session.appKey
            appSession.id = session.sessionID
            self.saveContext()
        }
    }

    func createInitMetrics(with metrics: InitMetrics) {
        viewContext.perform {
            let initMetrics = InitMetricsModel(context: self.viewContext)
            initMetrics.update(with: metrics)
            self.saveContext()
        }
    }

    func delete<T: NSManagedObject>(_ object: T) {
        viewContext.perform {
            self.viewContext.delete(object)
            self.saveContext()
        }
    }

    func deleteAll<T: NSManagedObject>(_ type: T.Type) {
        viewContext.perform {
            let request = NSFetchRequest<T>(entityName: String(describing: type))
            do {
                let results = try self.viewContext.fetch(request)
                results.forEach { self.viewContext.delete($0) }
                self.saveContext()
            } catch {
                self.logger.error("Unable to delete all entities: \(error)")
            }
        }
    }

    func updateAppSession(with session: AppSession) {
        viewContext.perform {
            guard let sessionModel = self.fetchAppSession(sessionID: session.sessionID) else { return }
            sessionModel.update(with: session)
            self.saveContext()
        }
    }

    func createOrGetPerformanceMetric(
        for placementID: String,
        session: AppSession,
        completion: @escaping (PerformanceMetricModel?) -> Void
    ) {
        viewContext.perform {
            guard let sessionModel = self.fetchAppSession(sessionID: session.sessionID) else {
                completion(nil)
                return
            }

            if let existingMetric = sessionModel
                .performanceMetrics?
                .compactMap({ $0 as? PerformanceMetricModel })
                .first(where: { $0.placementID == placementID }) {
                completion(existingMetric)
            } else {
                let newMetric = PerformanceMetricModel(context: self.viewContext)
                newMetric.placementID = placementID

                var performanceMetrics = sessionModel.performanceMetrics?.allObjects as? [PerformanceMetricModel] ?? []
                performanceMetrics.append(newMetric)

                sessionModel.performanceMetrics = NSSet(array: performanceMetrics)
                completion(newMetric)
            }
        }
    }

}



extension AppSessionModel {
    func update(with session: AppSession) {
        if self.metrics?.count != session.metrics.count {
            let metricModels = session.metrics.compactMap { metric -> SessionMetricModel? in
                guard let metric = metric as? SessionMetricSpend else { return nil }
                if let containsMetric = CoreDataManager.shared.fetchSessionMetric(timestamp: metric.timestamp) {
                    return containsMetric
                }
                let metricModel = SessionMetricModel(context: self.managedObjectContext!)
                metricModel.update(with: metric)
                return metricModel
            }
            metrics = NSSet(array: metricModels)
        }
        
//        if self.performanceMetrics?.count != session.performanceMetrics.count {
//            let performanceMetricModels = session.performanceMetrics.compactMap { metric -> PerformanceMetricModel? in
//                guard let metric = metric as? SessionMetricPerformance else { return nil }
//                let performanceMetricModel = PerformanceMetricModel(context: self.managedObjectContext!)
//                performanceMetricModel.update(with: metric)
//                return performanceMetricModel
//            }
//            performanceMetrics = NSSet(array: performanceMetricModels)
//        }
            //duration = session.sessionDuration
    }
}

extension InitMetricsModel {
    func update(with metrics: InitMetrics) {
        appKey = metrics.appKey
        startedAt = metrics.startedAt
        endedAt = metrics.endedAt
        //success = metrics.success
        sessionId = metrics.sessionId
    }
}

extension SessionMetricModel {
    func update(with metric: SessionMetricSpend) {
        self.placementID = metric.placementID
        self.timestamp = metric.timestamp
        self.type = metric.type.rawValue
        self.value = metric.value
    }
}

extension PerformanceMetricModel {
    func update(with metric: SessionMetricPerformance) {
        self.placementID = metric.placementID
        self.adLoadCount = Int16(metric.adLoadCount)
        self.adLoadLatency = metric.adLoadLatency
        self.bidRequestLatency = metric.bidRequestLatency
        self.bidResponseCount = Int16(metric.bidResponseCount)
        self.clickCount = Int16(metric.clickCount)
        self.closeCount = Int16(metric.closeCount)
        self.closeLatency = metric.closeLatency
        self.failToLoadAdCount = Int16(metric.failToLoadAdCount)
        self.impressionCount = Int16(metric.impressionCount)
    }
}

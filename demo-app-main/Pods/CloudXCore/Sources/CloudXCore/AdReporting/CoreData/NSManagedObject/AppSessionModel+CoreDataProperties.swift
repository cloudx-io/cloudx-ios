//
//  AppSessionModel+CoreDataProperties.swift
//  CloudXCore
//
//  Created by Bryan Boyko on 5/17/25.
//
//

import Foundation
import CoreData


extension AppSessionModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppSessionModel> {
        return NSFetchRequest<AppSessionModel>(entityName: "AppSessionModel")
    }

    @NSManaged public var appKey: String?
    @NSManaged public var duration: Double
    @NSManaged public var id: String?
    @NSManaged public var url: URL?
    @NSManaged public var metrics: NSSet?
    @NSManaged public var performanceMetrics: NSSet?

}

// MARK: Generated accessors for metrics
extension AppSessionModel {

    @objc(addMetricsObject:)
    @NSManaged public func addToMetrics(_ value: SessionMetricModel)

    @objc(removeMetricsObject:)
    @NSManaged public func removeFromMetrics(_ value: SessionMetricModel)

    @objc(addMetrics:)
    @NSManaged public func addToMetrics(_ values: NSSet)

    @objc(removeMetrics:)
    @NSManaged public func removeFromMetrics(_ values: NSSet)

}

// MARK: Generated accessors for performanceMetrics
extension AppSessionModel {

    @objc(addPerformanceMetricsObject:)
    @NSManaged public func addToPerformanceMetrics(_ value: PerformanceMetricModel)

    @objc(removePerformanceMetricsObject:)
    @NSManaged public func removeFromPerformanceMetrics(_ value: PerformanceMetricModel)

    @objc(addPerformanceMetrics:)
    @NSManaged public func addToPerformanceMetrics(_ values: NSSet)

    @objc(removePerformanceMetrics:)
    @NSManaged public func removeFromPerformanceMetrics(_ values: NSSet)

}

extension AppSessionModel : Identifiable {

}

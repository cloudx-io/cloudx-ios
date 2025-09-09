//
//  PerformanceMetricModel+CoreDataProperties.swift
//  CloudXCore
//
//  Created by Bryan Boyko on 5/17/25.
//
//

import Foundation
import CoreData


extension PerformanceMetricModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PerformanceMetricModel> {
        return NSFetchRequest<PerformanceMetricModel>(entityName: "PerformanceMetricModel")
    }

    @NSManaged public var adLoadCount: Int16
    @NSManaged public var adLoadLatency: Double
    @NSManaged public var bidRequestLatency: Double
    @NSManaged public var bidResponseCount: Int16
    @NSManaged public var clickCount: Int16
    @NSManaged public var closeCount: Int16
    @NSManaged public var closeLatency: Double
    @NSManaged public var failToLoadAdCount: Int16
    @NSManaged public var impressionCount: Int16
    @NSManaged public var placementID: String?
    @NSManaged public var session: AppSessionModel?

}

extension PerformanceMetricModel : Identifiable {

}

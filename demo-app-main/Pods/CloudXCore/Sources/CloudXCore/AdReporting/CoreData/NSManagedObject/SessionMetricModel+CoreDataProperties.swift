//
//  SessionMetricModel+CoreDataProperties.swift
//  CloudXCore
//
//  Created by Bryan Boyko on 5/17/25.
//
//

import Foundation
import CoreData


extension SessionMetricModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionMetricModel> {
        return NSFetchRequest<SessionMetricModel>(entityName: "SessionMetricModel")
    }

    @NSManaged public var placementID: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var type: String?
    @NSManaged public var value: Double
    @NSManaged public var session: AppSessionModel?

}

extension SessionMetricModel : Identifiable {

}

//
//  InitMetricsModel+CoreDataProperties.swift
//  CloudXCore
//
//  Created by Bryan Boyko on 5/17/25.
//
//

import Foundation
import CoreData


extension InitMetricsModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<InitMetricsModel> {
        return NSFetchRequest<InitMetricsModel>(entityName: "InitMetricsModel")
    }

    @NSManaged public var appKey: String?
    @NSManaged public var endedAt: Date?
    @NSManaged public var sessionId: String?
    @NSManaged public var startedAt: Date?
    @NSManaged public var success: Bool

}

extension InitMetricsModel : Identifiable {

}

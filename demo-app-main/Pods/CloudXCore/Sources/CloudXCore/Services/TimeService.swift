//
//  TimeService.swift
//  CloudXCore
//
//  Created by bkorda on 29.02.2024.
//

import Foundation

final class TimeService {
    
    var timeZoneOffset: Int
    
    init() {
        let timeZone = NSTimeZone.local.secondsFromGMT() / 60
        self.timeZoneOffset = timeZone
    }
    
}

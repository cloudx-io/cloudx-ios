//
//  Bool+Transform.swift
//  CloudXCore
//
//  Created by bkorda on 28.02.2024.
//

import Foundation

extension Bool {
  
  var numericStringValue: String {
    return self == true ? "1" : "0"
  }

  var intValue: Int {
    return self == true ? 1 : 0
  }
  
}

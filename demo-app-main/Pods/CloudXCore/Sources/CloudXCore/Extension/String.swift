//
//  String.swift
//  CloudXCore
//
//  Created by bkorda on 04.02.2024.
//

import Foundation

extension String {
    var cloudxClassName: String {
        self.components(separatedBy: .whitespaces).joined().capitalized
    }
}

extension String {
  func versionCompare(_ otherVersion: String) -> ComparisonResult {
    let versionDelimiter = "."

    var versionComponents = self.components(separatedBy: versionDelimiter)
    var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

    let zeroDiff = versionComponents.count - otherVersionComponents.count

    if zeroDiff == 0 {
      return self.compare(otherVersion, options: .numeric)
    } else {
      let zeros = Array(repeating: "0", count: abs(zeroDiff))
      if zeroDiff > 0 {
        otherVersionComponents.append(contentsOf: zeros)
      } else {
        versionComponents.append(contentsOf: zeros)
      }
      return versionComponents.joined(separator: versionDelimiter)
        .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
    }
  }
}

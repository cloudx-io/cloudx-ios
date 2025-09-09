//
//  Array+Average.swift
//
//
//  Created by bkorda on 04.07.2024.
//

import Foundation

extension Array where Element: FloatingPoint {
    func average() -> Element {
        guard count != 0 else { return Element(0) }
        
        let sum = reduce(0, +)
        return sum / Element(exactly: count)!
    }
}

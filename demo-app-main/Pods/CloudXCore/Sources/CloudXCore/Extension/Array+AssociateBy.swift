//
//  Array+AssociateBy.swift
//
//
//  Created by bkorda on 04.03.2024.
//

import Foundation

extension Array {
    public func associateBy<Key: Hashable>(_ selectKey: (Element) -> Key) -> [Key : Element] {
        var dict = [Key : Element]()
        self.forEach { dict[selectKey($0)] = $0 }
        return dict
    }
}

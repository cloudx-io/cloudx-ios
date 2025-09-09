//
//  NullEncodable.swift
//  CloudXCore
//
//  Created by bkorda on 29.02.2024.
//

import Foundation

@propertyWrapper
struct NullEncodable<T>: Encodable where T: Encodable {

  var wrappedValue: T?

  init(wrappedValue: T?) {
    // swift-format-ignore
    self.wrappedValue = wrappedValue
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch wrappedValue {
    case .some(let value): try container.encode(value)
    case .none: try container.encodeNil()
    }
  }
}

//
//  CommonNetworkData.swift
//  CloudXCore
//
//  Created by Bohdan Korda on 05.02.2024.
//

import Foundation

enum HTTPMethod: String {
    case get, post, delete, patch, put
}

enum ParameterEncoding {
    // swift-format-ignore: AlwaysUseLowerCamelCase
    case URL, JSON
}

typealias JSON = [String: Any]

/// A dictionary of parameters to apply to a `URLRequest`.
public typealias HTTPParameters = [String: Any]

/// A dictionary of headers to apply to a `URLRequest`.
public typealias HTTPHeaders = [String: String]

/// A dictionary of http url parameters.
public typealias HTTPURLParameters = [String: String]

protocol RequestParameters: Encodable {
    var urlParams: HTTPURLParameters { get }
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }
}

extension RequestParameters {

    var json: JSON? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = dateEncodingStrategy

        guard let jsonData = try? encoder.encode(self),
            let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? JSON
        else {
            return nil
        }
        return json
    }
    
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy {
        .secondsSince1970
    }

}

//
//  Extension.swift
//  CloudXCore
//
//  Created by bkorda on 08.02.2024.
//

import Foundation

extension URL {
    
    func appending(parameters: HTTPParameters?) -> URL? {
        guard let parameters = parameters, !parameters.isEmpty else {
            // Return the original URL if no parameters are provided.
            return self
        }

        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            // Can't create valid URLComponents from the URL.
            return nil
        }

        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: value as? String)
            queryItems.append(queryItem)
        }

        urlComponents.queryItems = queryItems

        return urlComponents.url
    }
    
}

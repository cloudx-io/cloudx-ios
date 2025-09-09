//
//  URLSession + Retry.swift
//  CloudXCore
//
//  Created by bkorda on 25.03.2024.
//

import Foundation

extension URLSession {
    
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil, maxRetries: Int, delay: TimeInterval) async throws -> (Data, URLResponse) {
        guard maxRetries > 0 else {
            return try await self.data(for: request)
        }
        
        for currentTry in 0 ..< maxRetries {
            let data: Data
            let response: URLResponse
            do {
                if #available(iOS 15.0, *) {
                    (data, response) = try await self.data(for: request, delegate: delegate)
                } else {
                    (data, response) = try await self.data(for: request)
                }
                guard let response = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                if response.statusCode < 500 {
                    return (data, response)
                }
            } catch {
                if maxRetries - currentTry == 1 {
                    throw error
                }
            }
            sleep(UInt32(delay))
        }

        throw URLError(.badServerResponse)
    }
    
}

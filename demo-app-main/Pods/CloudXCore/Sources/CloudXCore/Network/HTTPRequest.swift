//
//  HTTPRequest.swift
//  CloudXCore
//
//  Created by Bohdan Korda on 05.02.2024.
//

import Foundation

struct HTTPRequestError: Error, LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

struct HTTPRequest<Model: Decodable> {
    
    private let urlSession: URLSession
    private let logger = Logger(category: "HTTPRequest")
    
    init(timeout: TimeInterval?, urlSession: URLSession) {
        let config = urlSession.configuration
        let description = urlSession.sessionDescription
        if let timeout = timeout {
            config.timeoutIntervalForResource = timeout
            config.timeoutIntervalForRequest = timeout
        }
        self.urlSession = URLSession(configuration: config)
        self.urlSession.sessionDescription = description
    }
    
    func execute(
        method: HTTPMethod, baseUrl: URL, endpoint: String?, urlParameters: HTTPParameters?, requestBody: HTTPParameters?, headers: HTTPHeaders?, maxRetries: Int = 3, delay: TimeInterval = 1
    ) async throws -> Model {
        let data = try await executeRequestData(method: method, baseUrl: baseUrl, endpoint: endpoint, urlParameters: urlParameters, requestBody: requestBody, headers: headers, maxRetries: maxRetries, delay: delay)

        if let model = try? ResponseParser().decode(Model.self, from: data) {
            return model
        } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any] {
            throw NSError(domain: "Decoder error: Response: \(json)", code: 1)
        } else {
            let string = String(data: data, encoding: .utf8)
            throw HTTPRequestError(message: string ?? "Fail to parse JSON or String")
        }
    }
    
    func executeRequestData(
        method: HTTPMethod, baseUrl: URL, endpoint: String?, urlParameters: HTTPParameters?, requestBody: HTTPParameters?, headers: HTTPHeaders?, maxRetries: Int, delay: TimeInterval
    ) async throws -> Data {
        
        let request = makeRequest(
            for: baseUrl, endpoint: endpoint, method: method, urlParameters: urlParameters, requestBody: requestBody, headers: headers)
        let data: Data
        (data, _) = try await urlSession.data(for: request, delegate: nil, maxRetries: maxRetries, delay: delay)
        
        return data
    }
    
    private func makeRequest(
        for baseUrl: URL, endpoint: String?, method: HTTPMethod, urlParameters: HTTPParameters?, requestBody: HTTPParameters?, headers: HTTPHeaders?
    ) -> URLRequest {
        
        let requestData = requestBody.flatMap { try? JSONSerialization.data(withJSONObject: $0, options: []) }
        let url = makeURL(withBaseURL: baseUrl, endpoint: endpoint, parameters: urlParameters) ?? baseUrl
        
        var request = URLRequest(url: url)
        
        headers?.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        request.httpMethod = method.rawValue.uppercased()
        request.httpBody = requestData
        
        return request
    }
    
    private func makeURL(withBaseURL baseURL: URL, endpoint: String?, parameters: HTTPParameters?) -> URL? {
        guard let endpoint = endpoint else { return baseURL.appending(parameters: parameters) }
        
        if endpoint.starts(with: "http") {
            if let endpointURL = URL(string: endpoint) {
                return endpointURL.appending(parameters: parameters)
            } else if let encodedEndpoint = endpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let endpointURL = URL(string: encodedEndpoint)
            {
                return endpointURL.appending(parameters: parameters)
            }
            return baseURL.appending(parameters: parameters)
        }
        
        let finalURL = endpoint.isEmpty ? baseURL : baseURL.appendingPathComponent(endpoint)
        return finalURL.appending(parameters: parameters)
    }
}

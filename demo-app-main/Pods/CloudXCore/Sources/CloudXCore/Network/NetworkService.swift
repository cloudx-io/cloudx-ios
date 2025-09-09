//
//  NetworkService.swift
//  CloudXCore
//
//  Created by Bohdan Korda on 05.02.2024.
//

import Foundation

let defaultTimeOut: TimeInterval = 10

struct DefaultRequestModel: Decodable {}

protocol RequestExecutable {
    
    init(baseURL: URL, urlSession: URLSession)
    var headers: HTTPHeaders { get }
    
    func executeRequest<Model: Decodable>(
        method: HTTPMethod, endpoint: String?, urlParameters: HTTPParameters?, requestBody: HTTPParameters?, headers: HTTPHeaders?,
        timeout: TimeInterval?, maxRetries: Int, delay: TimeInterval
    ) async throws -> Model
    
    func executeRequest(
        method: HTTPMethod, endpoint: String?, urlParameters: HTTPParameters?, requestBody: HTTPParameters?, headers: HTTPHeaders?,
        timeout: TimeInterval?,
        maxRetries: Int, delay: TimeInterval
    ) async throws -> Data
    
    func executeFullPathRequest(
        method: HTTPMethod, endpoint: String?, urlParameters: HTTPParameters?, requestBody: HTTPParameters?, headers: HTTPHeaders?,
        url: URL,
        timeout: TimeInterval?,
        maxRetries: Int, delay: TimeInterval
    ) async throws -> Data
    
}

class BaseNetworkService: RequestExecutable {
    
    let baseURL: URL
    let urlSession: URLSession
    
    var headers: HTTPHeaders { [:] }
    
    required init(baseURL: URL, urlSession: URLSession) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }
    
    func executeRequest<Model: Decodable>(
        method: HTTPMethod = .post, endpoint: String?, urlParameters: HTTPParameters?, requestBody: HTTPParameters?, headers: HTTPHeaders?,
        timeout: TimeInterval? = defaultTimeOut, maxRetries: Int, delay: TimeInterval
    ) async throws -> Model {
        
        let httpRequest = HTTPRequest<Model>(timeout: timeout, urlSession: urlSession)
        let isDevURL =  baseURL.absoluteString.contains("type=static")
        var httpMethod = isDevURL ? .get : method
        var requestBody = isDevURL ? nil : requestBody
        return try await httpRequest.execute(
            method: httpMethod, baseUrl: baseURL, endpoint: endpoint, urlParameters: urlParameters, requestBody: requestBody, headers: headers, maxRetries: maxRetries, delay: delay)
    }
    
    @discardableResult
    func executeRequest(
        method: HTTPMethod = .post, endpoint: String?, urlParameters: HTTPParameters?, requestBody: HTTPParameters?, headers: HTTPHeaders?,
        timeout: TimeInterval? = defaultTimeOut,
        maxRetries: Int, delay: TimeInterval
    ) async throws -> Data {
        
        let httpRequest = HTTPRequest<DefaultRequestModel>(timeout: timeout, urlSession: urlSession)
        return try await httpRequest.executeRequestData(
            method: method, baseUrl: baseURL, endpoint: endpoint, urlParameters: urlParameters, requestBody: requestBody, headers: headers, maxRetries: maxRetries, delay: delay)
    }
    
    @discardableResult
    func executeFullPathRequest(
        method: HTTPMethod = .get, endpoint: String? = nil, urlParameters: HTTPParameters? = nil, requestBody: HTTPParameters? = nil, headers: HTTPHeaders? = nil,
        url: URL,
        timeout: TimeInterval? = defaultTimeOut,
        maxRetries: Int, delay: TimeInterval
    ) async throws -> Data {
        
        let httpRequest = HTTPRequest<DefaultRequestModel>(timeout: timeout, urlSession: urlSession)
        return try await httpRequest.executeRequestData(
            method: method, baseUrl: url, endpoint: endpoint, urlParameters: urlParameters, requestBody: requestBody, headers: headers, maxRetries: maxRetries, delay: delay)
    }
    
}

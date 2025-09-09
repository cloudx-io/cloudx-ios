//
//  HTTPResponse.swift
//  CloudXCore
//
//  Created by Bohdan Korda on 05.02.2024.
//

import Foundation

private enum StringConstants {

    static var unknownError: String { "unknown error" }

}

enum ResponseMappingError: Error {

    case invalid

}

extension ResponseMappingError: LocalizedError {

}

struct HTTPResponse {

    static let unknownError = 1000

    let httpStatusCode: Int?
    let error: Error?
    let responseData: Data?

    let httpURLRequest: URLRequest?
    let httpURLResponse: HTTPURLResponse?

    internal init(
        httpStatusCode: Int?, error: Error?, responseData: Data? = nil, httpURLRequest: URLRequest?, httpURLResponse: HTTPURLResponse? = nil
    ) {
        self.httpStatusCode = httpStatusCode

        self.error =
            error == nil
            ? NSError(
                domain: "NetworkResponse", code: HTTPResponse.unknownError,
                userInfo: [NSLocalizedFailureReasonErrorKey: StringConstants.unknownError, NSLocalizedDescriptionKey: StringConstants.unknownError])
            : error

        self.responseData = responseData
        self.httpURLRequest = httpURLRequest
        self.httpURLResponse = httpURLResponse
    }

    var isStatusCode200: Bool {
        httpStatusCode == 200
    }

    var isStatusCode204: Bool {
        httpStatusCode == 204
    }

    var headers: [String: String]? {
        return self.httpURLResponse?.allHeaderFields as? [String: String]
    }

}

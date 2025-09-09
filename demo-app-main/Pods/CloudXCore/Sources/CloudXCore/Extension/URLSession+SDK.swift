//
//  URLSession+SDK.swift
//  CloudXCore
//
//  Created by bkorda on 21.02.2024.
//

import Foundation

extension URLSession {
  static func cloudxSession(with identifier: String) -> URLSession {
    let sessionConfiguration = URLSessionConfiguration.default
    sessionConfiguration.waitsForConnectivity = true
    let urlSession = URLSession(configuration: sessionConfiguration)
    urlSession.sessionDescription = "cloudx.sdk." + identifier

    return urlSession
  }
}

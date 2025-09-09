//
//  LiveInitService.swift
//  CloudXCore
//
//  Created by bkorda on 21.02.2024.
//

import Foundation

class LiveInitService: InitService {

  private lazy var networkInitService: SDKInitNetworkService = {
    SDKInitNetworkService(baseURL: URLProvider.initApiUrl, urlSession: URLSession.cloudxSession(with: "init"))
  }()

  func initSDK(appKey: String) async throws -> SDKConfig.Response {
    return try await networkInitService.initSDK(appKey: appKey)
  }
}

//
//  InitService.swift
//  CloudXCore
//
//  Created by bkorda on 08.02.2024.
//

import Foundation

protocol InitService {
    func initSDK(appKey: String) async throws -> SDKConfig.Response
}

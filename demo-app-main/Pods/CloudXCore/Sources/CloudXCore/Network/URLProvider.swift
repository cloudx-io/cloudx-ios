//
//  URLProvider.swift
//  CloudXCore
//
//  Created by Bohdan Korda on 05.02.2024.
//

import Foundation

enum URLProvider {
    private static let scheme = "https://"

    private static let prodInitApiUrl = "https://pro-dev.cloudx.io/sdk"

    static var initApiUrl: URL {
        #if DEBUG
        if let urlString = UserDefaults.standard.string(forKey: "CloudXInitURL"), !urlString.isEmpty {
            return URL(string: urlString)!
        } else {
            return URL(string: prodInitApiUrl)!
        }
        #else
        return URL(string: prodInitApiUrl)!
        #endif
    }
}

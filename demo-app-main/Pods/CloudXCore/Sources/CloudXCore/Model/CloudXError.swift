//
//  CloudXError.swift
//  CloudXCore
//
//  Created by bkorda on 08.02.2024.
//

import Foundation

/// An error type that represents the CloudX SDK errors.
public enum CloudXError: Int, Error {
    
    /// SDK will throw this error If initialisation failed.
    case failToInitSDK = 100
    /// If SDK initialisation is in progress and you try to initialise it again, this error will be thrown.
    case sdkInitialisationInProgress = 101
    /// If SDK was initialized without any adapters
    case sdkInitializedWithoutAdapters = 102
    
    /// General ad error.
    case generalAdError = 200
    /// Somemthing went wrong with the banner view.
    case bannerViewError = 201
    /// Something went wrong with the native view.
    case nativeViewError = 202
    
    /// There is no such placement id in SDK configuration. Please check the placement id on dashboard.
    case invalidPlacement = 2002
    /// No ads loaded in queue yet.
    case noAdsLoaded = 2003
    /// No bid token source.
    case noBidTokenSource = 2004
}

extension CloudXError: LocalizedError {
    
    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case .failToInitSDK:
            return "fail to init SDK"
        case .sdkInitialisationInProgress:
            return "sdk initialisation in progress"
        case .sdkInitializedWithoutAdapters:
            return "No adapters found"
        case .bannerViewError:
            return "View for banner is nil"
        case .nativeViewError:
            return "View for native is nil"
        case .generalAdError:
            return "General ad error"
        case .invalidPlacement:
            return "There is no such placement id in SDK configuration. Please check the placement id on dashboard."
        case .noAdsLoaded:
            return "No ads loaded in queue yet"
        case .noBidTokenSource:
            return "No bid token source"
        }
    }
    
}

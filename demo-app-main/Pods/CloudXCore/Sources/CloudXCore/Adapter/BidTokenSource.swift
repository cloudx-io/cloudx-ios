//
//  BidTokenSource.swift
//  
//
//  Created by bkorda on 05.03.2024.
//

import UIKit

/// Implement this protocol for networks that requierbid token for the bid request.
public protocol BidTokenSource: Instanciable {
    
    /// Returns bid toke from ad network.
    func getToken() async throws -> [String : String]
    
}

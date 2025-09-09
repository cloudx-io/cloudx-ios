//
//  Instanciable.swift
//
//
//  Created by bkorda on 01.03.2024.
//

import Foundation

/// Implement this protocol to create instances of classes.
public protocol Instanciable {
    
    /// Creates an instance of the class.
    static func createInstance() -> Self
}

/// Implement this protocol to create instances of Obj-C classes.
@objc public protocol Instantiable: AnyObject {
    /// Creates an instance of the Obj-C class.
    @objc static func createInstance() -> AnyObject
}


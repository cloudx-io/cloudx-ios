//
//  ClassLoader.swift
//  
//
//  Created by bkorda on 04.03.2024.
//

import Foundation

enum ClassLoader {
    static func loadClass(namespace: String, className: String) -> Instanciable.Type? {
        let adapterClass = NSClassFromString("\(namespace).\(className)") as? Instanciable.Type
        return adapterClass
    }
}

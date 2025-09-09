//
//  DIContainer.swift
//  CloudXCore
//
//  Created by bkorda on 22.02.2024.
//

import Foundation

enum ServiceType {
    case singleton
    case newSingleton
    case new
    case automatic
}

protocol DIContainerProtocol {
    func register<Service>(type: Service.Type, _ factory: @autoclosure @escaping () -> Service)
    func resolve<Service>(_ resolveType: ServiceType, _ type: Service.Type) -> Service?
}

final class DIContainer: DIContainerProtocol {
    
    static let shared = DIContainer()
    private init() {}
    
    private var factories: [String: () -> Any] = [:]
    private var cache: [String: Any] = [:]
    
    func register<Service>(type: Service.Type, _ factory: @autoclosure @escaping () -> Service) {
        factories[String(describing: type.self)] = factory
    }
    
    func resolve<Service>(_ resolveType: ServiceType = .automatic, _ type: Service.Type) -> Service? {
        let serviceName = String(describing: type.self)
        switch resolveType {
        case .singleton:
            if let service = cache[serviceName] as? Service {
                return service
            } else {
                let service = factories[serviceName]?() as? Service
                
                if let service = service {
                    cache[serviceName] = service
                }
                
                return service
            }
        case .newSingleton:
            let service = factories[serviceName]?() as? Service
            
            if let service = service {
                cache[serviceName] = service
            }
            
            return service
        case .automatic:
            fallthrough
        case .new:
            return factories[serviceName]?() as? Service
        }
    }
}

@propertyWrapper
struct Service<Service> {

    var service: Service

    init(_ type: ServiceType = .automatic) {
        guard let service = DIContainer.shared.resolve(type, Service.self) else {
            let serviceName = String(describing: Service.self)
            fatalError("No service of type \(serviceName) registered!")
        }

        self.service = service
    }

    var wrappedValue: Service {
        get { self.service }
        mutating set { service = newValue }
    }
}

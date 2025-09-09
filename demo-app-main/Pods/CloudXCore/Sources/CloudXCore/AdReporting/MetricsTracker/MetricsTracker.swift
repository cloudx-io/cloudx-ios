//
//  MetricsTracker.swift
//
//
//  Created by bkorda on 10.04.2024.
//

import Foundation

final class MetricsTracker {
    
    private let logger = Logger(category: "MetricsTracker")
    
    func trySendPendingMetrics() async {
        //TODO: Task group
        let models = CoreDataManager.shared.fetch(AppSessionModel.self)
        for model in models {
            //do not remove current session
            if let appsessionService = DIContainer.shared.resolve(.singleton, AppSessionService.self),
               appsessionService.currentSession.sessionID == model.id {
                continue
            }
            guard let url = model.url else {
                CoreDataManager.shared.delete(model)
                break
            }
            let networkService = MetricsNetworkService(baseURL: url, urlSession: URLSession.cloudxSession(with: "io.cloudx.metrics"))
            do {
                try await networkService.trackEndSession(session: model)
                CoreDataManager.shared.delete(model)
            } catch {
                logger.error("Failed to end session: \(error)")
            }
        }
        
        CoreDataManager.shared.saveContext()
    }
    
}

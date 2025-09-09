//
//  LogStorage.swift
//  CloudXDemo
//
//  Created by bkorda on 19.03.2024.
//

import Foundation
import Combine

protocol LogStorage {
    var logsPublisher: AnyPublisher<Log?, Never> { get }
    func addLog(type: Log.LogType, prefix: String, message: String)
    var logs: [Log] { get }
}

class LogStorageClass: LogStorage {
    static let shared = LogStorageClass()
    
    private(set) var logs: [Log] = []
    
    private let logsSubject: PassthroughSubject<Log?, Never> = .init()
    var logsPublisher: AnyPublisher<Log?, Never> {
        logsSubject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    func addLog(type: Log.LogType, prefix: String, message: String) {
        let log = Log(type: type, prefix: prefix, message: message)
        logs.append(log)
        logsSubject.send(log)
    }
}

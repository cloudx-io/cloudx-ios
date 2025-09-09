//
//  LogView.swift
//  CloudXDemo
//
//  Created by bkorda on 19.03.2024.
//

import SwiftUI
import Combine

struct LogView: View {
    
    @ObservedObject var logDelegate: LogsDelegate
    
    var body: some View {
        List(logDelegate.logs, id: \.id) { log in
            LogRow(log: log)
                .listRowSeparator(.hidden)
                .listRowInsets(.init()) // remove insets
        }
        .environment(\.defaultMinListRowHeight, 0)
        .listStyle(.plain)
    }
}

struct LogRow: View {
    
    let log: Log
    var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:mmm"
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top) {
            Text(formatter.string(from: log.date))
                .foregroundStyle(.gray)
                .font(.caption)
            Text(log.prefix.appending(":"))
                .foregroundStyle(log.textColor)
                .font(.caption)
            Text(log.message)
                .foregroundStyle(log.type == .error ? log.textColor : .gray)
                .font(.caption)
        }
    }
}

struct Log: Identifiable {
    let id = UUID()
    
    enum LogType {
        case error
        case warning
        case info
        case success
    }
    
    private enum Colors {
        static let errorColor = Color.red
        static let warningColor = Color.orange
        static let infoColor = Color.blue
        static let successColor = Color.green
    }
    
    let type: LogType
    let prefix: String
    let message: String
    let date = Date()
    
    var textColor: Color {
        switch self.type {
        case .error:
            Colors.errorColor
        case .info:
            Colors.infoColor
        case .warning:
            Colors.warningColor
        case .success:
            Colors.successColor
        }
    }
    
}

class LogsDelegate: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    var cancellable: AnyCancellable?
    
    var logs: [Log] = [] {
        didSet { objectWillChange.send() }
    }
    
    init(logStorage: LogStorage) {
        logStorage.logs.forEach { log in
            self.logs.append(log)
        }
        
        cancellable = logStorage.logsPublisher
            .sink { [weak self] log in
                guard let log = log else { return }
                self?.logs.append(log)
            }
    }
}

#Preview {
    
    class LogStr: LogStorage {
        var logsPublisher: AnyPublisher<Log?, Never> = PassthroughSubject().eraseToAnyPublisher()
        
        func addLog(type: Log.LogType, prefix: String, message: String) {
            
        }
        
        var logs: [Log] = [.init(type: .error, prefix: "SDK", message: "very long text that is not in just oble linefail to load"), .init(type: .info, prefix: "Ad", message: "did load"), .init(type: .warning, prefix: "SDK", message: "retry")]
        
    }
    
    @StateObject var logs = LogsDelegate(logStorage: LogStr())
    
    return LogView(logDelegate: logs)
}

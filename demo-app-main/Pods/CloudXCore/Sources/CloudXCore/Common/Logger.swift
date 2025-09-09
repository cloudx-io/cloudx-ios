//
//  Logger.swift
//  CloudXCore
//
//  Created by  bkorda on 04.03.2024.
//

import Foundation
import os.log

/// A logging utility class that wraps `os_log` functionality to provide a low overhead logging system.
/// The error and fault levels are highlighted with yellow and red bubbles in Console app.
/// Because these APIs are very efficient, they can be widely used without slowing down your app.
///
final class Logger {
  private let osLog: OSLog
  private var subsystem = "io.cloudx.sdk"
  private var category = "cloudx-sdk"
  let enabled: Bool
  let verbose: Bool

  /// Initializes a new logger for the specified category.
  ///
  /// - Parameter category: A string to categorize logs. This is used in the subsystem of the OSLog.
  init(category: String) {
    #if DEBUG
      enabled = true
      verbose = ProcessInfo().environment["CLOUDX_VERBOSE_LOG"] ?? "" == "1"
    #else
      enabled = ProcessInfo().environment["CLOUDX_VERBOSE_LOG"] ?? "" == "1"
      verbose = enabled
    #endif
    osLog = enabled ? OSLog(subsystem: subsystem, category: category) : OSLog.disabled
    self.category = category
  }

  private func log(_ message: String, type: OSLogType = .default) {
    guard enabled else { return }
    if type == .debug && !verbose { return }

    os_log("%{public}@", log: osLog, type: type, message)
  }

  // More efficient logger with privacy support
  private func logStatic(_ message: StaticString, type: OSLogType = .default, _ args: CVarArg...) {
    guard enabled else { return }
    if type == .debug && !verbose { return }

    os_log(message, log: osLog, type: type, args)
  }

  /// Logs a debug message.
  /// Fastest in terms of performance because messages are not persisted.
  /// They are discarded when the logs aren't being streamed.
  /// Further, the Swift compiler uses sophisticated optimizations to ensure that the,
  /// code that creates the messages is not even executed when the debug messages are discarded.
  /// This means that you can log verbose messages at the debug level and
  /// call expensive functions to construct messages.
  ///
  /// - Parameter message: The debug message to log.
  func debug(_ message: String) {
    log(message, type: .debug)
  }

  func debug(_ message: StaticString, _ args: CVarArg...) {
    logStatic(message, type: .debug, args)
  }

  /// Logs an informational message.
  /// Info error messages are mostly not persisted, except when they are generated a few moments before a log collect command.
  ///
  /// - Parameter message: The informational message to log.
  func info(_ message: String) {
    log(message, type: .info)
  }

  func info(_ message: StaticString, _ args: CVarArg...) {
    logStatic(message, type: .info, args)
  }

  /// Logs an notice message which is the default level also called as Notice level
  /// Notices indicate that the message is absolutely essential for troubleshooting.
  /// Persisted for a short duration, typically a few days
  /// Info error messages are mostly not persisted, except when they are generated a few moments before a log collect command.
  ///
  /// - Parameter message: The informational message to log.
  func log(_ message: String) {
    log(message, type: .default)
  }

  func log(_ message: StaticString, _ args: CVarArg...) {
    logStatic(message, type: .default, args)
  }

  /// Logs an error message, including file, line, and function information in debug builds.
  /// Error log messages are persisted and you can retrieve them later
  /// Typically, the messages will be persisted for a few days.
  /// However, it depends on the storage space on your device.
  /// Slowest log level after Fault
  ///
  /// - Parameters:
  ///   - message: The error message to log.
  func error(_ message: String) {
    log(message, type: .error)
  }

  func error(_ message: StaticString, _ args: CVarArg...) {
    logStatic(message, type: .error, args)
  }

  /// Logs a fault message, including file, line, and function information in debug builds.
  /// You should use it to record situations that arise due to a potential bug in the program. For example, to record that an assumption that the program expects to hold is violated at runtime.
  /// Error log messages are persisted and you can retrieve them later
  /// Typically, the messages will be persisted for a few days.
  /// However, it depends on the storage space on your device.
  /// Slowest log level
  /// - Parameters:
  ///   - message: The fault message to log.
  func fault(_ message: String) {
    log(message, type: .fault)
  }

  func fault(_ message: StaticString, _ args: CVarArg...) {
    logStatic(message, type: .fault, args)
  }

}

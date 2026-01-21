//
//  ConsoleMetrics.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 21/1/26.
//

import Foundation
import os.log

/// A metrics implementation that logs events to the console.
///
/// `ConsoleMetrics` uses the unified logging system to output
/// network metrics in a human-readable format. This is useful
/// for development and debugging.
///
/// ## Usage
///
/// ```swift
/// let metrics = ConsoleMetrics(subsystem: "com.myapp.network")
/// let interceptor = MetricsInterceptor(metrics: metrics)
///
/// let config = NetworkClientConfiguration(
///     interceptors: [interceptor]
/// )
/// ```
///
/// ## Log Categories
///
/// Events are logged under the following categories:
/// - `request`: Successful request completions
/// - `error`: Request errors
/// - `retry`: Retry attempts
/// - `cache`: Cache hits and misses
public actor ConsoleMetrics: NetworkMetrics {
    
    private let requestLogger: Logger
    private let errorLogger: Logger
    private let retryLogger: Logger
    private let cacheLogger: Logger
    
    /// Creates a new console metrics logger.
    ///
    /// - Parameter subsystem: The subsystem identifier for logging.
    ///   Defaults to `com.swiftnetwork.metrics`.
    public init(subsystem: String = "com.swiftnetwork.metrics") {
        self.requestLogger = Logger(subsystem: subsystem, category: "request")
        self.errorLogger = Logger(subsystem: subsystem, category: "error")
        self.retryLogger = Logger(subsystem: subsystem, category: "retry")
        self.cacheLogger = Logger(subsystem: subsystem, category: "cache")
    }
    
    public func recordRequest(_ event: RequestMetricEvent) {
        let tagsString = self.formatTags(event.tags)
        let bytesFormatted = self.formatBytes(event.responseBodySize)
        requestLogger.info("""
            [\(event.method.rawValue)] \(event.url.absoluteString) \
            → \(event.statusCode) \
            (\(String(format: "%.3f", event.duration))s) \
            [\(bytesFormatted)]\(tagsString)
            """)
    }
    
    public func recordError(_ event: ErrorMetricEvent) {
        let tagsString = self.formatTags(event.tags)
        errorLogger.error("""
            [\(event.method.rawValue)] \(event.url.absoluteString) \
            → ERROR: \(String(describing: event.error)) \
            (\(String(format: "%.3f", event.duration))s)\(tagsString)
            """)
    }
    
    public func recordRetry(_ event: RetryMetricEvent) {
        let tagsString = self.formatTags(event.tags)
        retryLogger.warning("""
            [\(event.method.rawValue)] \(event.url.absoluteString) \
            → RETRY #\(event.attemptNumber): \(event.reason)\(tagsString)
            """)
    }
    
    public func recordCacheHit(_ event: CacheMetricEvent) {
        let tagsString = self.formatTags(event.tags)
        cacheLogger.debug("""
            [\(event.method.rawValue)] \(event.url.absoluteString) \
            → CACHE \(event.result.rawValue.uppercased())\(tagsString)
            """)
    }
    
    private func formatTags(_ tags: [String: String]) -> String {
        guard !tags.isEmpty else { return "" }
        let tagsArray = tags.map { "\($0.key)=\($0.value)" }.sorted()
        return " [" + tagsArray.joined(separator: ", ") + "]"
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

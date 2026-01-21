//
//  AggregateMetrics.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Foundation

/// A metrics collector that aggregates statistics over time.
///
/// `AggregateMetrics` tracks request counts, success rates,
/// error rates, and performance percentiles. It provides
/// a snapshot of these metrics on demand.
///
/// ## Usage
///
/// ```swift
/// let metrics = AggregateMetrics()
/// let interceptor = MetricsInterceptor(metrics: metrics)
///
/// // Later, retrieve statistics
/// let stats = await metrics.snapshot()
/// print("Success rate: \(stats.successRate)%")
/// print("P95 latency: \(stats.p95Duration)s")
/// ```
///
/// ## Thread Safety
///
/// This actor is fully thread-safe and can be safely accessed
/// from multiple concurrent requests.
public actor AggregateMetrics: NetworkMetrics {
    
    /// A snapshot of aggregated metrics.
    public struct Snapshot: Sendable {
        /// Total number of requests completed.
        public let totalRequests: Int
        
        /// Number of successful requests (2xx status codes).
        public let successfulRequests: Int
        
        /// Number of failed requests.
        public let failedRequests: Int
        
        /// Success rate as a percentage (0-100).
        public var successRate: Double {
            guard totalRequests > 0 else { return 0 }
            return Double(successfulRequests) / Double(totalRequests) * 100
        }
        
        /// Average request duration in seconds.
        public let averageDuration: TimeInterval
        
        /// Median request duration in seconds.
        public let medianDuration: TimeInterval
        
        /// 95th percentile duration in seconds.
        public let p95Duration: TimeInterval
        
        /// 99th percentile duration in seconds.
        public let p99Duration: TimeInterval
        
        /// Total bytes sent in requests.
        public let totalBytesSent: Int
        
        /// Total bytes received in responses.
        public let totalBytesReceived: Int
        
        /// Total number of retry attempts.
        public let totalRetries: Int
        
        /// Number of cache hits.
        public let cacheHits: Int
        
        /// Number of cache misses.
        public let cacheMisses: Int
        
        /// Cache hit rate as a percentage (0-100).
        public var cacheHitRate: Double {
            let total = cacheHits + cacheMisses
            guard total > 0 else { return 0 }
            return Double(cacheHits) / Double(total) * 100
        }
    }
    
    private var requestDurations: [TimeInterval] = []
    private var successCount = 0
    private var errorCount = 0
    private var bytesSent = 0
    private var bytesReceived = 0
    private var retryCount = 0
    private var cacheHitCount = 0
    private var cacheMissCount = 0
    
    /// Creates a new aggregate metrics collector.
    public init() {}
    
    public func recordRequest(_ event: RequestMetricEvent) {
        requestDurations.append(event.duration)
        
        if (200..<300).contains(event.statusCode) {
            successCount += 1
        } else {
            errorCount += 1
        }
        
        bytesSent += event.requestBodySize ?? 0
        bytesReceived += event.responseBodySize
    }
    
    public func recordError(_ event: ErrorMetricEvent) {
        requestDurations.append(event.duration)
        errorCount += 1
    }
    
    public func recordRetry(_ event: RetryMetricEvent) {
        retryCount += 1
    }
    
    public func recordCacheHit(_ event: CacheMetricEvent) {
        switch event.result {
        case .hit, .revalidated:
            cacheHitCount += 1
        case .miss:
            cacheMissCount += 1
        }
    }
    
    /// Returns a snapshot of current metrics.
    ///
    /// This method calculates percentiles and averages from
    /// the collected data. The snapshot is a point-in-time
    /// view and does not reflect subsequent metric updates.
    ///
    /// - Returns: A snapshot of aggregated metrics.
    public func snapshot() -> Snapshot {
        let sortedDurations = requestDurations.sorted()
        
        let average = sortedDurations.isEmpty
            ? 0
            : sortedDurations.reduce(0, +) / Double(sortedDurations.count)
        
        let median = percentile(sortedDurations, 50)
        let p95 = percentile(sortedDurations, 95)
        let p99 = percentile(sortedDurations, 99)
        
        return Snapshot(
            totalRequests: successCount + errorCount,
            successfulRequests: successCount,
            failedRequests: errorCount,
            averageDuration: average,
            medianDuration: median,
            p95Duration: p95,
            p99Duration: p99,
            totalBytesSent: bytesSent,
            totalBytesReceived: bytesReceived,
            totalRetries: retryCount,
            cacheHits: cacheHitCount,
            cacheMisses: cacheMissCount
        )
    }
    
    /// Resets all collected metrics.
    ///
    /// This method clears all accumulated data, returning
    /// the metrics collector to its initial state.
    public func reset() {
        requestDurations.removeAll()
        successCount = 0
        errorCount = 0
        bytesSent = 0
        bytesReceived = 0
        retryCount = 0
        cacheHitCount = 0
        cacheMissCount = 0
    }
    
    private func percentile(_ values: [TimeInterval], _ p: Int) -> TimeInterval {
        guard !values.isEmpty else { return 0 }
        guard p > 0 && p < 100 else { return values.last ?? 0 }
        
        let index = Int(ceil(Double(values.count) * Double(p) / 100.0)) - 1
        let clampedIndex = max(0, min(values.count - 1, index))
        return values[clampedIndex]
    }
}

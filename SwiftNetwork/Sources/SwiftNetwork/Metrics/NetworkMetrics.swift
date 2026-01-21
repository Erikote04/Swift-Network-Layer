//
//  NetworkMetrics.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Foundation

/// A protocol that defines how network metrics are recorded.
///
/// Conforming types can record various network events such as
/// request completion, errors, retries, and cache hits.
///
/// Metrics are recorded asynchronously and should not block
/// the main request execution path.
public protocol NetworkMetrics: Sendable {
    
    /// Records metrics for a completed request.
    ///
    /// This method is called after a request completes successfully.
    ///
    /// - Parameter event: The request event containing timing and metadata.
    func recordRequest(_ event: RequestMetricEvent) async
    
    /// Records an error that occurred during request execution.
    ///
    /// - Parameter event: The error event containing failure details.
    func recordError(_ event: ErrorMetricEvent) async
    
    /// Records a retry attempt for a failed request.
    ///
    /// - Parameter event: The retry event containing attempt metadata.
    func recordRetry(_ event: RetryMetricEvent) async
    
    /// Records a cache hit or miss.
    ///
    /// - Parameter event: The cache event containing cache status.
    func recordCacheHit(_ event: CacheMetricEvent) async
}

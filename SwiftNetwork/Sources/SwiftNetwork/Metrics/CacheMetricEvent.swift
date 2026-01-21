//
//  CacheMetricEvent.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Foundation

/// Represents metrics for cache operations.
///
/// This event tracks cache hits, misses, and validation status.
public struct CacheMetricEvent: Sendable {
    
    /// The result of the cache operation.
    public enum CacheResult: String, Sendable {
        /// The response was served from cache.
        case hit
        /// The response was not in cache and fetched from network.
        case miss
        /// The cached response was revalidated with the server.
        case revalidated
    }
    
    /// The HTTP method of the request.
    public let method: HTTPMethod
    
    /// The URL of the request.
    public let url: URL
    
    /// The cache operation result.
    public let result: CacheResult
    
    /// The time of the cache operation.
    public let timestamp: Date
    
    /// Custom tags for categorizing metrics.
    public let tags: [String: String]
    
    /// Creates a new cache metric event.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - url: The request URL.
    ///   - result: The cache operation result.
    ///   - timestamp: When the operation occurred.
    ///   - tags: Custom tags for categorization.
    public init(
        method: HTTPMethod,
        url: URL,
        result: CacheResult,
        timestamp: Date,
        tags: [String: String] = [:]
    ) {
        self.method = method
        self.url = url
        self.result = result
        self.timestamp = timestamp
        self.tags = tags
    }
}

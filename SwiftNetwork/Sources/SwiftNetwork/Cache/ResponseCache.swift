//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An in-memory cache for HTTP responses.
///
/// `ResponseCache` stores successful GET responses and serves them
/// when valid cached entries are available. Cache entries expire
/// based on a configurable time-to-live (TTL).
public actor ResponseCache {

    private var storage: [URL: CacheEntry] = [:]
    private let ttl: TimeInterval

    /// Creates a new response cache.
    ///
    /// - Parameter ttl: The time-to-live for cached responses, in seconds.
    ///   Defaults to 60 seconds.
    public init(ttl: TimeInterval = 60) {
        self.ttl = ttl
    }

    /// Returns a cached response for a request if available and valid.
    ///
    /// - Parameter request: The request to look up in the cache.
    /// - Returns: A cached `Response`, or `nil` if none is available or expired.
    public func cachedResponse(for request: Request) -> Response? {
        guard
            request.method == .get,
            let entry = storage[request.url],
            !isExpired(entry)
        else {
            return nil
        }

        return entry.response
    }

    /// Stores a response in the cache.
    ///
    /// Only responses for GET requests are cached.
    ///
    /// - Parameter response: The response to store.
    public func store(_ response: Response) {
        guard response.request.method == .get else { return }

        storage[response.request.url] = CacheEntry(
            response: response,
            timestamp: Date()
        )
    }

    /// Determines whether a cache entry has expired.
    ///
    /// - Parameter entry: The cache entry to evaluate.
    /// - Returns: `true` if the entry is expired.
    private func isExpired(_ entry: CacheEntry) -> Bool {
        Date().timeIntervalSince(entry.timestamp) > ttl
    }
}

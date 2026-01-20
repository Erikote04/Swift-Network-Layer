//
//  CacheStorage.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 20/1/26.
//

import Foundation

/// Defines storage operations for cached HTTP responses.
///
/// `CacheStorage` abstracts the cache implementation, allowing different
/// storage strategies (in-memory, disk, hybrid) and testable implementations.
public protocol CacheStorage: Sendable {
    
    /// Returns a cached response for a request if available and valid.
    ///
    /// - Parameter request: The request to look up in the cache.
    /// - Returns: A cached `Response`, or `nil` if none is available or expired.
    func cachedResponse(for request: Request) async -> Response?
    
    /// Returns a cached entry for a request if available.
    ///
    /// Unlike `cachedResponse(for:)`, this returns the full cache entry
    /// including metadata. It does NOT check for expiration.
    ///
    /// - Parameter request: The request to look up in the cache.
    /// - Returns: A `CacheEntry`, or `nil` if none is available.
    func cachedEntry(for request: Request) async -> CacheEntry?
    
    /// Stores a response in the cache.
    ///
    /// - Parameter response: The response to store.
    func store(_ response: Response) async
    
    /// Removes a cached entry for a request.
    ///
    /// - Parameter request: The request whose cached entry should be removed.
    func remove(for request: Request) async
}

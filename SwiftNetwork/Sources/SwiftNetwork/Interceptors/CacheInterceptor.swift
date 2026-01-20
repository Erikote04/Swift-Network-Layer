//
//  CacheInterceptor.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An interceptor that provides response caching for GET requests.
///
/// `CacheInterceptor` serves cached responses when available and stores
/// successful responses based on the request's cache policy. It supports
/// advanced HTTP caching semantics including conditional requests,
/// ETag validation, and Cache-Control directives.
///
/// ## Cache-Control Directive Handling
///
/// The interceptor respects all standard Cache-Control directives:
/// - `no-store`: Response is never cached
/// - `no-cache`: Cached response is always revalidated before use
/// - `must-revalidate`: Stale responses must be revalidated
/// - `max-age`: Defines freshness lifetime
/// - `private`/`public`: Controls cache visibility (currently informational)
public struct CacheInterceptor: Interceptor {

    private let cache: any CacheStorage

    /// Creates a new cache interceptor.
    ///
    /// - Parameter cache: The cache storage used to store and retrieve responses.
    public init(cache: any CacheStorage) {
        self.cache = cache
    }

    /// Intercepts a request to return cached responses or store new ones.
    ///
    /// Behavior varies by cache policy:
    /// - `.useCache`: Return cached response if available and fresh
    /// - `.ignoreCache`: Always fetch from network
    /// - `.revalidate`: Conditional request with ETag/Last-Modified
    /// - `.respectHeaders`: Follow HTTP Cache-Control directives
    ///
    /// - Parameter chain: The interceptor chain.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced during request execution.
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let request = chain.request
        let policy = request.cachePolicy ?? .useCache
        
        switch policy {
        case .useCache:
            return try await handleUseCache(request: request, chain: chain)
            
        case .ignoreCache:
            return try await handleIgnoreCache(request: request, chain: chain)
            
        case .revalidate:
            return try await handleRevalidate(request: request, chain: chain)
            
        case .respectHeaders:
            return try await handleRespectHeaders(request: request, chain: chain)
        }
    }
    
    // MARK: - Policy Handlers
    
    /// Handles `.useCache` policy: Return cached response if available.
    private func handleUseCache(
        request: Request,
        chain: InterceptorChainProtocol
    ) async throws -> Response {
        // Try to get cached response
        if let cached = await cache.cachedResponse(for: request) {
            return cached
        }
        
        // Fetch from network and cache
        let response = try await chain.proceed(request)
        
        if (200..<300).contains(response.statusCode) {
            await cache.store(response)
        }
        
        return response
    }
    
    /// Handles `.ignoreCache` policy: Always fetch from network.
    private func handleIgnoreCache(
        request: Request,
        chain: InterceptorChainProtocol
    ) async throws -> Response {
        let response = try await chain.proceed(request)
        
        // Still cache successful responses for future use (unless no-store)
        if (200..<300).contains(response.statusCode) {
            await cache.store(response)
        }
        
        return response
    }
    
    /// Handles `.revalidate` policy: Conditional request with ETag/Last-Modified.
    private func handleRevalidate(
        request: Request,
        chain: InterceptorChainProtocol
    ) async throws -> Response {
        // Get cached entry (not just response, need metadata)
        guard let cachedEntry = await cache.cachedEntry(for: request) else {
            // No cache, fetch normally
            let response = try await chain.proceed(request)
            
            if (200..<300).contains(response.statusCode) {
                await cache.store(response)
            }
            
            return response
        }
        
        // Build conditional request with updated headers
        var headers = request.headers
        
        if let etag = cachedEntry.etag {
            headers["If-None-Match"] = etag
        }
        
        if let lastModified = cachedEntry.lastModified {
            headers["If-Modified-Since"] = lastModified
        }
        
        let conditionalRequest = Request(
            method: request.method,
            url: request.url,
            headers: headers,
            body: request.body,
            timeout: request.timeout,
            cachePolicy: request.cachePolicy
        )
        
        // Make conditional request
        let response = try await chain.proceed(conditionalRequest)
        
        // If 304 Not Modified, return cached response
        if response.statusCode == 304 {
            return cachedEntry.response
        }
        
        // Otherwise, cache new response
        if (200..<300).contains(response.statusCode) {
            await cache.store(response)
        }
        
        return response
    }
    
    /// Handles `.respectHeaders` policy: Follow HTTP Cache-Control directives.
    private func handleRespectHeaders(
        request: Request,
        chain: InterceptorChainProtocol
    ) async throws -> Response {
        // Get cached entry to check directives
        if let cachedEntry = await cache.cachedEntry(for: request) {
            // Check if entry should never have been stored
            if cachedEntry.shouldNotStore {
                // Invalidate and fetch fresh
                await cache.remove(for: request)
                return try await fetchAndCacheIfAllowed(request: request, chain: chain)
            }
            
            // Check if must revalidate (no-cache or expired + must-revalidate)
            if cachedEntry.mustRevalidate {
                return try await handleRevalidate(request: request, chain: chain)
            }
            
            // Check if entry is still fresh
            if !cachedEntry.isExpired {
                return cachedEntry.response
            }
            
            // Expired, try to revalidate
            return try await handleRevalidate(request: request, chain: chain)
        }
        
        // No cache, fetch from network
        return try await fetchAndCacheIfAllowed(request: request, chain: chain)
    }
    
    /// Fetches from network and caches if allowed by directives.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - chain: The interceptor chain.
    /// - Returns: The response from the network.
    /// - Throws: Any error during execution.
    private func fetchAndCacheIfAllowed(
        request: Request,
        chain: InterceptorChainProtocol
    ) async throws -> Response {
        let response = try await chain.proceed(request)
        
        // Parse Cache-Control to check if we should cache
        if let cacheControl = response.headers["Cache-Control"] {
            let directives = CacheControlDirectives(headerValue: cacheControl)
            
            if directives.noStore {
                // Do not cache this response
                return response
            }
        }
        
        // Cache if successful
        if (200..<300).contains(response.statusCode) {
            await cache.store(response)
        }
        
        return response
    }
}

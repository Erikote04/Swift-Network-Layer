//
//  CachePolicy.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// Defines caching behavior for a request.
///
/// `CachePolicy` determines whether a request should use cached responses,
/// respect HTTP cache headers, or always fetch fresh data from the network.
///
/// ## Cache Policy Behaviors
///
/// - **useCache**: Uses cached responses when available without validation
/// - **ignoreCache**: Always performs network requests, bypassing cache
/// - **revalidate**: Uses cache but revalidates with server using conditional requests
/// - **respectHeaders**: Follows HTTP cache-control directives from response headers
///
/// ## Example Usage
///
/// ```swift
/// // Simple caching
/// let request = Request(
///     method: .get,
///     url: url,
///     cachePolicy: .useCache
/// )
///
/// // Revalidate with server
/// let revalidatingRequest = Request(
///     method: .get,
///     url: url,
///     cachePolicy: .revalidate
/// )
///
/// // Follow HTTP standards
/// let standardRequest = Request(
///     method: .get,
///     url: url,
///     cachePolicy: .respectHeaders
/// )
/// ```
public enum CachePolicy: Sendable {

    /// Use a cached response if available and valid.
    ///
    /// This policy returns cached responses immediately without network validation.
    /// The cache entry must not be expired based on its stored expiration time.
    ///
    /// Best for:
    /// - Static resources that rarely change
    /// - Reducing network usage
    /// - Improving response time
    case useCache

    /// Ignore cached responses and always perform a network request.
    ///
    /// This policy bypasses the cache entirely and always fetches fresh data.
    /// Successful responses may still be cached for future requests.
    ///
    /// Best for:
    /// - Critical data that must be fresh
    /// - User-initiated refresh actions
    /// - Write operations (POST, PUT, DELETE)
    case ignoreCache
    
    /// Use cached response but revalidate with the server.
    ///
    /// This policy uses cached responses but sends conditional requests to the
    /// server using `If-None-Match` (ETag) or `If-Modified-Since` headers.
    /// If the server responds with `304 Not Modified`, the cached response is used.
    ///
    /// Benefits:
    /// - Ensures data freshness while minimizing bandwidth
    /// - Supports incremental updates
    /// - Respects server-side changes
    ///
    /// Best for:
    /// - Content that changes occasionally
    /// - Balancing freshness and performance
    /// - APIs with ETag support
    case revalidate
    
    /// Respect HTTP cache-control headers from responses.
    ///
    /// This policy follows standard HTTP caching semantics:
    /// - `Cache-Control: max-age=N` - Cache for N seconds
    /// - `Cache-Control: no-cache` - Revalidate before using cache
    /// - `Cache-Control: no-store` - Don't cache at all
    /// - `Expires` header - Cache until expiration date
    ///
    /// The cache automatically handles:
    /// - Age calculation
    /// - Expiration checking
    /// - Conditional requests (304 responses)
    ///
    /// Best for:
    /// - REST APIs following HTTP standards
    /// - CDN-backed resources
    /// - Properly configured backend services
    case respectHeaders
}

// MARK: - Deprecated

extension CachePolicy {
    
    /// Ignore cached responses and always perform a network request.
    ///
    /// - Note: This is deprecated. Use ``ignoreCache`` instead for clarity.
    @available(*, deprecated, renamed: "ignoreCache", message: "Use .ignoreCache for consistency with other policies")
    public static var reloadIgnoringCache: CachePolicy {
        .ignoreCache
    }
}

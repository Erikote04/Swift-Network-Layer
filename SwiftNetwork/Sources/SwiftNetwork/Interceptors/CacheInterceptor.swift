//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An interceptor that provides response caching for GET requests.
///
/// `CacheInterceptor` serves cached responses when available and stores
/// successful responses based on the request's cache policy.
public struct CacheInterceptor: Interceptor {

    private let cache: ResponseCache

    /// Creates a new cache interceptor.
    ///
    /// - Parameter cache: The response cache used to store and retrieve responses.
    public init(cache: ResponseCache) {
        self.cache = cache
    }

    /// Intercepts a request to return cached responses or store new ones.
    ///
    /// - Parameter chain: The interceptor chain.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced during request execution.
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let request = chain.request

        guard request.cachePolicy == .useCache else {
            let response = try await chain.proceed(request)
            await cache.store(response)
            return response
        }

        if let cached = await cache.cachedResponse(for: request) {
            return cached
        }

        let response = try await chain.proceed(request)

        if (200..<300).contains(response.statusCode) {
            await cache.store(response)
        }

        return response
    }
}

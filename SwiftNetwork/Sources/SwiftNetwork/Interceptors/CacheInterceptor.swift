//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public struct CacheInterceptor: Interceptor {

    private let cache: ResponseCache

    public init(cache: ResponseCache) {
        self.cache = cache
    }

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

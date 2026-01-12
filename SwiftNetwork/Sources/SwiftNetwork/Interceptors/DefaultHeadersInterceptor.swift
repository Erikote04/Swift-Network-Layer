//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An interceptor that injects default headers into requests.
///
/// `DefaultHeadersInterceptor` allows dynamic header injection by
/// evaluating a provider closure at request time.
public struct DefaultHeadersInterceptor: Interceptor {

    private let headersProvider: @Sendable () -> HTTPHeaders

    /// Creates a new default headers interceptor.
    ///
    /// - Parameter headersProvider: A closure that provides headers to be merged
    ///   into each request.
    public init(headersProvider: @escaping @Sendable () -> HTTPHeaders) {
        self.headersProvider = headersProvider
    }

    /// Intercepts a request to merge additional headers.
    ///
    /// - Parameter chain: The interceptor chain.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced during request execution.
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let extraHeaders = headersProvider()
        let mergedRequest = Request(
            method: chain.request.method,
            url: chain.request.url,
            headers: chain.request.headers.merging(extraHeaders),
            body: chain.request.body,
            timeout: chain.request.timeout
        )

        return try await chain.proceed(mergedRequest)
    }
}

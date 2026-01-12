//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An interceptor that applies a default timeout to requests.
///
/// `TimeoutInterceptor` sets a timeout on requests that do not
/// already define one.
public struct TimeoutInterceptor: Interceptor {

    private let timeout: TimeInterval

    /// Creates a new timeout interceptor.
    ///
    /// - Parameter timeout: The timeout interval to apply.
    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

    /// Intercepts a request to apply a timeout if missing.
    ///
    /// - Parameter chain: The interceptor chain.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced during request execution.
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let request = chain.request

        guard request.timeout == nil else {
            return try await chain.proceed(request)
        }

        let updated = Request(
            method: request.method,
            url: request.url,
            headers: request.headers,
            body: request.body,
            timeout: timeout
        )

        return try await chain.proceed(updated)
    }
}

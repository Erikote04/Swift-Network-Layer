//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public struct TimeoutInterceptor: Interceptor {

    private let timeout: TimeInterval

    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }

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

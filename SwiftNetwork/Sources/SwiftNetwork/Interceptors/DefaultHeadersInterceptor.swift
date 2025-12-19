//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public struct DefaultHeadersInterceptor: Interceptor {

    private let headersProvider: @Sendable () -> HTTPHeaders

    public init(headersProvider: @escaping @Sendable () -> HTTPHeaders) {
        self.headersProvider = headersProvider
    }

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

//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public struct AuthInterceptor: Interceptor {
    private let tokenStore: TokenStore
    private let authenticator: Authenticator

    public init(
        tokenStore: TokenStore,
        authenticator: Authenticator
    ) {
        self.tokenStore = tokenStore
        self.authenticator = authenticator
    }

    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        var request = chain.request

        if let token = await tokenStore.currentToken() {
            request = Request(
                method: request.method,
                url: request.url,
                headers: request.headers.merging(["Authorization": "Bearer \(token)"]),
                body: request.body,
                timeout: request.timeout
            )
        }

        let response = try await chain.proceed(request)

        guard response.statusCode == 401 else {
            return response
        }

        guard let newRequest = try await authenticator.authenticate(
            request: request,
            response: response
        ) else {
            return response
        }

        return try await chain.proceed(newRequest)
    }
}

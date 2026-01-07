//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public struct AuthInterceptor: Interceptor {

    let tokenStore: TokenStore
    let authenticator: Authenticator

    private let coordinator: AuthRefreshCoordinator

    public init(
        tokenStore: TokenStore,
        authenticator: Authenticator
    ) {
        self.tokenStore = tokenStore
        self.authenticator = authenticator
        self.coordinator = AuthRefreshCoordinator()
    }

    init(
        tokenStore: TokenStore,
        authenticator: Authenticator,
        coordinator: AuthRefreshCoordinator
    ) {
        self.tokenStore = tokenStore
        self.authenticator = authenticator
        self.coordinator = coordinator
    }

    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let originalRequest = chain.request

        if let token = await tokenStore.currentToken() {
            var headers = originalRequest.headers
            headers["Authorization"] = "Bearer \(token)"

            let authenticatedRequest = Request(
                method: originalRequest.method,
                url: originalRequest.url,
                headers: headers,
                body: originalRequest.body,
                timeout: originalRequest.timeout,
                cachePolicy: originalRequest.cachePolicy
            )

            let response = try await chain.proceed(authenticatedRequest)

            guard response.statusCode == 401 else {
                return response
            }

            let refreshedToken = try await coordinator.refreshIfNeeded(
                tokenStore: tokenStore
            ) {
                if let newRequest = try await authenticator.authenticate(
                    request: authenticatedRequest,
                    response: response
                ),
                let authHeader = newRequest.headers["Authorization"] {
                    return authHeader.replacingOccurrences(of: "Bearer ", with: "")
                }
                
                return nil
            }

            guard let token = refreshedToken else {
                return response
            }

            var retryHeaders = originalRequest.headers
            retryHeaders["Authorization"] = "Bearer \(token)"

            let retryRequest = Request(
                method: originalRequest.method,
                url: originalRequest.url,
                headers: retryHeaders,
                body: originalRequest.body,
                timeout: originalRequest.timeout,
                cachePolicy: originalRequest.cachePolicy
            )

            return try await chain.proceed(retryRequest)
        }

        return try await chain.proceed(originalRequest)
    }
}

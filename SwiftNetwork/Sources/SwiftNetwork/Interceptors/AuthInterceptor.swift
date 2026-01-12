//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An interceptor that handles authenticated requests and token refresh.
///
/// `AuthInterceptor` automatically attaches an authorization token to outgoing
/// requests and handles authentication challenges (such as HTTP 401 responses)
/// by refreshing the token when needed.
///
/// Token refresh operations are coordinated to ensure that only one refresh
/// happens concurrently across multiple requests.
public struct AuthInterceptor: Interceptor {

    /// The store responsible for providing and updating authentication tokens.
    let tokenStore: TokenStore

    /// The authenticator responsible for refreshing tokens.
    let authenticator: Authenticator

    private let coordinator: AuthRefreshCoordinator

    /// Creates a new authentication interceptor.
    ///
    /// - Parameters:
    ///   - tokenStore: The token store used to read and update the current token.
    ///   - authenticator: The authenticator used to refresh expired tokens.
    public init(
        tokenStore: TokenStore,
        authenticator: Authenticator
    ) {
        self.tokenStore = tokenStore
        self.authenticator = authenticator
        self.coordinator = AuthRefreshCoordinator()
    }

    /// Creates a new authentication interceptor with a shared refresh coordinator.
    ///
    /// This initializer is intended for internal use to ensure that multiple
    /// interceptor instances share the same refresh coordination logic.
    ///
    /// - Parameters:
    ///   - tokenStore: The token store used to read and update the current token.
    ///   - authenticator: The authenticator used to refresh expired tokens.
    ///   - coordinator: A shared refresh coordinator.
    init(
        tokenStore: TokenStore,
        authenticator: Authenticator,
        coordinator: AuthRefreshCoordinator
    ) {
        self.tokenStore = tokenStore
        self.authenticator = authenticator
        self.coordinator = coordinator
    }

    /// Intercepts a request to attach authentication headers and handle token refresh.
    ///
    /// - Parameter chain: The interceptor chain.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced during request execution or authentication.
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let originalRequest = chain.request

        guard let usedToken = await tokenStore.currentToken() else {
            return try await chain.proceed(originalRequest)
        }

        var headers = originalRequest.headers
        headers["Authorization"] = "Bearer \(usedToken)"

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

        if let currentToken = await tokenStore.currentToken(),
           currentToken != usedToken {

            var retryHeaders = originalRequest.headers
            retryHeaders["Authorization"] = "Bearer \(currentToken)"

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
}

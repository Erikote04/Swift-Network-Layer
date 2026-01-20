//
//  AuthInterceptor.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An interceptor that handles authentication by adding tokens to requests
/// and automatically refreshing expired tokens.
///
/// `AuthInterceptor` can work standalone or integrate with `AuthManager`
/// for automatic token refresh and expiration handling.
public final class AuthInterceptor: Interceptor, @unchecked Sendable {
    
    public let tokenStore: TokenStore
    public let authenticator: Authenticator?
    private let coordinator: AuthRefreshCoordinator
    private let authManager: AuthManager?
    private let headerName: String
    private let tokenPrefix: String
    
    /// Creates a new authentication interceptor with token store and authenticator.
    ///
    /// This initializer is used for backward compatibility with the existing API.
    ///
    /// - Parameters:
    ///   - tokenStore: The token store providing authentication tokens.
    ///   - authenticator: Optional authenticator for handling 401 responses.
    ///   - coordinator: Shared refresh coordinator to prevent duplicate refreshes.
    public init(
        tokenStore: TokenStore,
        authenticator: Authenticator? = nil,
        coordinator: AuthRefreshCoordinator? = nil
    ) {
        self.tokenStore = tokenStore
        self.authenticator = authenticator
        self.coordinator = coordinator ?? AuthRefreshCoordinator()
        self.authManager = nil
        self.headerName = "Authorization"
        self.tokenPrefix = "Bearer"
    }
    
    /// Creates a new authentication interceptor with an auth manager.
    ///
    /// This initializer enables automatic token refresh and expiration handling.
    ///
    /// - Parameters:
    ///   - authManager: The authentication manager providing tokens and refresh logic.
    ///   - headerName: The HTTP header name for the token (default: "Authorization").
    ///   - tokenPrefix: The prefix for the token value (default: "Bearer").
    public init(
        authManager: AuthManager,
        headerName: String = "Authorization",
        tokenPrefix: String = "Bearer"
    ) {
        self.authManager = authManager
        self.tokenStore = InMemoryTokenStore() // Dummy, not used
        self.authenticator = nil
        self.coordinator = AuthRefreshCoordinator()
        self.headerName = headerName
        self.tokenPrefix = tokenPrefix
    }
    
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        
        // If using AuthManager, try to refresh token if needed
        if let authManager = authManager {
            _ = try? await authManager.refreshTokenIfNeeded()
            
            let authenticatedRequest = await addAuthToken(to: chain.request, from: authManager)
            let response = try await chain.proceed(authenticatedRequest)
            
            // If we get 401, try to refresh and retry once
            if response.statusCode == 401 {
                if let _ = try? await authManager.refreshToken() {
                    let retryRequest = await addAuthToken(to: chain.request, from: authManager)
                    return try await chain.proceed(retryRequest)
                }
            }
            
            return response
        }
        
        // Legacy path: use tokenStore and authenticator
        let token = await tokenStore.currentToken()
        var headers = chain.request.headers
        
        if let token = token {
            headers[headerName] = "\(tokenPrefix) \(token)"
        }
        
        let authenticatedRequest = Request(
            method: chain.request.method,
            url: chain.request.url,
            headers: headers,
            body: chain.request.body,
            timeout: chain.request.timeout,
            cachePolicy: chain.request.cachePolicy
        )
        
        let response = try await chain.proceed(authenticatedRequest)
        
        // Handle 401 with authenticator if available - use coordinator to deduplicate
        if response.statusCode == 401, let authenticator = authenticator {
            let newToken = try await coordinator.refreshIfNeeded(tokenStore: tokenStore) {
                // Authenticate and extract new token
                guard let newRequest = try await authenticator.authenticate(
                    request: authenticatedRequest,
                    response: response
                ) else {
                    return nil
                }
                
                // Extract token from the authenticated request
                return newRequest.headers[self.headerName]?
                    .replacingOccurrences(of: "\(self.tokenPrefix) ", with: "")
            }
            
            if let newToken = newToken {
                var retryHeaders = chain.request.headers
                retryHeaders[headerName] = "\(tokenPrefix) \(newToken)"
                
                let retryRequest = Request(
                    method: chain.request.method,
                    url: chain.request.url,
                    headers: retryHeaders,
                    body: chain.request.body,
                    timeout: chain.request.timeout,
                    cachePolicy: chain.request.cachePolicy
                )
                
                return try await chain.proceed(retryRequest)
            }
        }
        
        return response
    }
    
    // MARK: - Private
    
    private func addAuthToken(to request: Request, from authManager: AuthManager) async -> Request {
        guard let token = await authManager.currentCredentials?.accessToken else {
            return request
        }
        
        var headers = request.headers
        headers[headerName] = "\(tokenPrefix) \(token)"
        
        return Request(
            method: request.method,
            url: request.url,
            headers: headers,
            body: request.body,
            timeout: request.timeout,
            cachePolicy: request.cachePolicy
        )
    }
}

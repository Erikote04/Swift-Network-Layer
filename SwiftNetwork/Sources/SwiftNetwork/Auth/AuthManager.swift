//
//  AuthManager.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// Manages authentication state and token lifecycle.
///
/// `AuthManager` coordinates authentication flows, token storage,
/// refresh operations, and logout across different providers.
public actor AuthManager {
    
    private let tokenStore: TokenStore
    private let refreshCoordinator: AuthRefreshCoordinator
    private var credentials: AuthCredentials?
    
    /// Creates a new authentication manager.
    ///
    /// - Parameter tokenStore: The store responsible for persisting tokens.
    public init(tokenStore: TokenStore) {
        self.tokenStore = tokenStore
        self.refreshCoordinator = AuthRefreshCoordinator()
    }
    
    /// Performs login using the specified provider.
    ///
    /// This method delegates to the provider's `login()` method,
    /// stores the resulting credentials, and updates the token store.
    ///
    /// - Parameter provider: The authentication provider to use.
    /// - Returns: The obtained authentication credentials.
    /// - Throws: An error if authentication fails.
    public func login(provider: AuthProvider) async throws -> AuthCredentials {
        let creds = try await provider.login()
        credentials = creds
        await tokenStore.updateToken(creds.accessToken)
        return creds
    }
    
    /// Logs out and clears all stored credentials.
    ///
    /// After calling this method, `isAuthenticated` returns `false`
    /// and `currentCredentials` returns `nil`.
    public func logout() async {
        credentials = nil
        await tokenStore.updateToken("")
    }
    
    /// Refreshes the current access token using the refresh token.
    ///
    /// This method coordinates with the refresh coordinator to ensure
    /// only one refresh operation occurs at a time, even if multiple
    /// requests trigger it simultaneously.
    ///
    /// - Returns: The new access token, or `nil` if refresh fails.
    /// - Throws: An error if the refresh operation fails.
    public func refreshToken() async throws -> String? {
        guard let refreshToken = credentials?.refreshToken else {
            return nil
        }
        
        return try await refreshCoordinator.refreshIfNeeded(tokenStore: tokenStore) {
            // Subclasses or implementations should override this behavior
            // For now, return nil to indicate refresh is not implemented
            return nil
        }
    }
    
    /// Whether the user is currently authenticated.
    public var isAuthenticated: Bool {
        credentials != nil
    }
    
    /// The current authentication credentials, if any.
    public var currentCredentials: AuthCredentials? {
        credentials
    }
}

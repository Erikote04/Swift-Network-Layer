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
///
/// ## Topics
/// ### Authentication
/// - ``login(provider:)``
/// - ``logout()``
/// - ``refreshTokenIfNeeded()``
/// ### State
/// - ``isAuthenticated``
/// - ``currentCredentials``
/// - ``needsRefresh``
public actor AuthManager {
    
    private let tokenStore: TokenStore
    private let refreshCoordinator: AuthRefreshCoordinator
    private var credentials: AuthCredentials?
    private var refreshProvider: (@Sendable (String) async throws -> AuthCredentials)?
    
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
        refreshProvider = nil
        await tokenStore.updateToken("")
    }
    
    /// Configures a custom refresh provider.
    ///
    /// The refresh provider is called when a token needs to be refreshed.
    /// It receives the current refresh token and should return new credentials.
    ///
    /// - Parameter provider: A closure that performs token refresh.
    public func setRefreshProvider(_ provider: @escaping @Sendable (String) async throws -> AuthCredentials) {
        self.refreshProvider = provider
    }
    
    /// Refreshes the token if it's expired or expiring soon.
    ///
    /// This method checks if the current token needs refresh and performs
    /// the refresh operation if necessary.
    ///
    /// - Returns: The new access token, or the current token if no refresh was needed.
    /// - Throws: An error if the refresh operation fails.
    public func refreshTokenIfNeeded() async throws -> String? {
        guard let currentCreds = credentials else {
            return nil
        }
        
        // Check if token needs refresh
        guard currentCreds.isExpiringSoon() else {
            return currentCreds.accessToken
        }
        
        guard let refreshToken = currentCreds.refreshToken else {
            return nil
        }
        
        guard let refreshProvider = refreshProvider else {
            return nil
        }
        
        return try await refreshCoordinator.refreshIfNeeded(tokenStore: tokenStore) {
            let newCreds = try await refreshProvider(refreshToken)
            await self.updateCredentials(newCreds)
            return newCreds.accessToken
        }
    }
    
    /// Manually refreshes the access token using the refresh token.
    ///
    /// - Returns: The new access token, or `nil` if refresh fails.
    /// - Throws: An error if the refresh operation fails.
    public func refreshToken() async throws -> String? {
        guard let refreshToken = credentials?.refreshToken else {
            return nil
        }
        
        guard let refreshProvider = refreshProvider else {
            return nil
        }
        
        return try await refreshCoordinator.refreshIfNeeded(tokenStore: tokenStore) {
            let newCreds = try await refreshProvider(refreshToken)
            await self.updateCredentials(newCreds)
            return newCreds.accessToken
        }
    }
    
    /// Whether the user is currently authenticated.
    public var isAuthenticated: Bool {
        credentials != nil && !(credentials?.isExpired() ?? true)
    }
    
    /// Whether the current token needs refresh.
    public var needsRefresh: Bool {
        credentials?.isExpiringSoon() ?? false
    }
    
    /// The current authentication credentials, if any.
    public var currentCredentials: AuthCredentials? {
        credentials
    }
    
    // MARK: - Private
    
    private func updateCredentials(_ newCredentials: AuthCredentials) {
        credentials = newCredentials
    }
}

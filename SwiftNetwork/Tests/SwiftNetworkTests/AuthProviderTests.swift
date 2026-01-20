//
//  AuthProviderTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Auth Provider Tests")
struct AuthProviderTests {
    
    @Test("AuthCredentials stores all properties correctly")
    func credentialsStoreProperties() {
        let credentials = AuthCredentials(
            accessToken: "test_access",
            refreshToken: "test_refresh",
            expiresIn: 3600,
            provider: .google
        )
        
        #expect(credentials.accessToken == "test_access")
        #expect(credentials.refreshToken == "test_refresh")
        #expect(credentials.expiresIn == 3600)
        #expect(credentials.provider == .google)
    }
    
    @Test("AuthCredentials can be created without optional fields")
    func credentialsWithoutOptionalFields() {
        let credentials = AuthCredentials(
            accessToken: "token",
            provider: .apple
        )
        
        #expect(credentials.accessToken == "token")
        #expect(credentials.refreshToken == nil)
        #expect(credentials.expiresIn == nil)
        #expect(credentials.provider == .apple)
    }
    
    @Test("AuthProviderType display names are correct")
    func providerTypeDisplayNames() {
        #expect(AuthProviderType.apple.displayName == "Apple")
        #expect(AuthProviderType.google.displayName == "Google")
    }
    
    @Test("AuthProviderType equality works correctly")
    func providerTypeEquality() {
        #expect(AuthProviderType.apple == .apple)
        #expect(AuthProviderType.google == .google)
        #expect(AuthProviderType.apple != .google)
    }
    
    @Test("AuthError equality works correctly")
    func authErrorEquality() {
        #expect(AuthError.cancelled == .cancelled)
        #expect(AuthError.invalidCredentials == .invalidCredentials)
        #expect(AuthError.providerNotConfigured == .providerNotConfigured)
        #expect(AuthError.unsupportedPlatform == .unsupportedPlatform)
        
        let error1 = AuthError.authenticationFailed(underlying: NSError(domain: "test", code: 1))
        let error2 = AuthError.authenticationFailed(underlying: NSError(domain: "test", code: 2))
        #expect(error1 == error2) // Both are authenticationFailed regardless of underlying
        
        #expect(AuthError.cancelled != .invalidCredentials)
    }
}

@Suite("Auth Manager Tests")
struct AuthManagerTests {
    
    @Test("Login stores credentials and updates token store")
    func loginStoresCredentials() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "mock_token",
                refreshToken: "mock_refresh",
                expiresIn: 3600,
                provider: .apple
            )
        )
        
        let credentials = try await manager.login(provider: provider)
        
        #expect(credentials.accessToken == "mock_token")
        #expect(credentials.refreshToken == "mock_refresh")
        #expect(credentials.provider == .apple)
        #expect(await manager.isAuthenticated == true)
        #expect(await tokenStore.currentToken() == "mock_token")
    }
    
    @Test("Logout clears credentials and token")
    func logoutClearsState() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "token",
                provider: .apple
            )
        )
        
        _ = try await manager.login(provider: provider)
        #expect(await manager.isAuthenticated == true)
        
        await manager.logout()
        
        #expect(await manager.isAuthenticated == false)
        #expect(await manager.currentCredentials == nil)
        #expect(await tokenStore.currentToken() == "")
    }
    
    @Test("Manager tracks authentication state correctly")
    func tracksAuthenticationState() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        
        #expect(await manager.isAuthenticated == false)
        #expect(await manager.currentCredentials == nil)
        
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "token",
                provider: .google
            )
        )
        
        let credentials = try await manager.login(provider: provider)
        
        #expect(await manager.isAuthenticated == true)
        #expect(await manager.currentCredentials == credentials)
    }
    
    @Test("Login failure does not change auth state")
    func loginFailureDoesNotChangeState() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let provider = FailingAuthProvider()
        
        #expect(await manager.isAuthenticated == false)
        
        do {
            _ = try await manager.login(provider: provider)
            Issue.record("Expected login to throw")
        } catch {
            #expect(error as? AuthError == .authenticationFailed(underlying: nil))
        }
        
        #expect(await manager.isAuthenticated == false)
        #expect(await manager.currentCredentials == nil)
    }
    
    @Test("Refresh token returns nil when no refresh token available")
    func refreshWithoutRefreshToken() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "token",
                refreshToken: nil,
                provider: .apple
            )
        )
        
        _ = try await manager.login(provider: provider)
        
        let refreshed = try await manager.refreshToken()
        #expect(refreshed == nil)
    }
}

// MARK: - Mock Providers

private struct MockAuthProvider: AuthProvider {
    let credentials: AuthCredentials
    
    func login() async throws -> AuthCredentials {
        credentials
    }
}

private struct FailingAuthProvider: AuthProvider {
    func login() async throws -> AuthCredentials {
        throw AuthError.authenticationFailed(underlying: nil)
    }
}

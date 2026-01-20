//
//  AuthManagerTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("AuthManager Tests")
struct AuthManagerTests {
    
    @Test("Login stores credentials and updates token store")
    func loginStoresCredentials() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let provider = FakeAuthProvider()
        
        let credentials = try await manager.login(provider: provider)
        
        #expect(credentials.accessToken == "fake_access_token")
        #expect(credentials.provider == .apple)
        #expect(await manager.isAuthenticated == true)
        #expect(await tokenStore.currentToken() == "fake_access_token")
    }
    
    @Test("Logout clears credentials and token")
    func logoutClearsState() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let provider = FakeAuthProvider()
        
        _ = try await manager.login(provider: provider)
        await manager.logout()
        
        #expect(await manager.isAuthenticated == false)
        #expect(await manager.currentCredentials == nil)
        #expect(await tokenStore.currentToken() == "")
    }
    
    @Test("Manager tracks authentication state")
    func tracksAuthenticationState() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        
        #expect(await manager.isAuthenticated == false)
        
        let provider = FakeAuthProvider()
        _ = try await manager.login(provider: provider)
        
        #expect(await manager.isAuthenticated == true)
    }
}

// MARK: - Fakes

private struct FakeAuthProvider: AuthProvider {
    func login() async throws -> AuthCredentials {
        AuthCredentials(
            accessToken: "fake_access_token",
            refreshToken: "fake_refresh_token",
            expiresIn: 3600,
            provider: .apple
        )
    }
}

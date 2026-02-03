//
//  EnhancedAuthManagerTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Enhanced Auth Manager Tests", .tags(.auth))
struct EnhancedAuthManagerTests {
    
    @Test("Manager with expiring token triggers refresh")
    func managerTriggersRefreshForExpiringToken() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let refreshCounter = RefreshCounter()
        
        await manager.setRefreshProvider { refreshToken in
            await refreshCounter.increment()
            return AuthCredentials(
                accessToken: "refreshed_token",
                refreshToken: refreshToken,
                expiresIn: 3600,
                provider: .google
            )
        }
        
        // Login with a token that expires soon
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "expiring_token",
                refreshToken: "refresh",
                expiresIn: 100, // Expires in 100s
                provider: .google
            )
        )
        
        _ = try await manager.login(provider: provider)
        
        // Trigger refresh check (token is expiring soon with default threshold)
        let token = try await manager.refreshTokenIfNeeded()
        
        let count = await refreshCounter.count
        #expect(count == 1)
        #expect(token == "refreshed_token")
    }
    
    @Test("Manager does not refresh fresh tokens")
    func managerDoesNotRefreshFreshTokens() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let refreshCounter = RefreshCounter()
        
        await manager.setRefreshProvider { _ in
            await refreshCounter.increment()
            return AuthCredentials(
                accessToken: "should_not_be_called",
                provider: .google
            )
        }
        
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "fresh_token",
                refreshToken: "refresh",
                expiresIn: 3600, // Expires in 1 hour
                provider: .google
            )
        )
        
        _ = try await manager.login(provider: provider)
        
        let token = try await manager.refreshTokenIfNeeded()
        
        let count = await refreshCounter.count
        #expect(count == 0)
        #expect(token == "fresh_token")
    }
    
    @Test("Manager tracks expired credentials as unauthenticated")
    func expiredCredentialsNotAuthenticated() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "expired",
                expiresIn: -100, // Already expired
                provider: .apple
            )
        )
        
        _ = try await manager.login(provider: provider)
        
        #expect(await manager.isAuthenticated == false)
    }
    
    @Test("Manager detects when token needs refresh")
    func managerDetectsNeedsRefresh() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "token",
                expiresIn: 200, // Expires soon
                provider: .google
            )
        )
        
        _ = try await manager.login(provider: provider)
        
        #expect(await manager.needsRefresh == true)
    }
}

// MARK: - Mocks

private actor RefreshCounter {
    private(set) var count = 0
    
    func increment() {
        count += 1
    }
}

private struct MockAuthProvider: AuthProvider {
    let credentials: AuthCredentials
    
    func login() async throws -> AuthCredentials {
        credentials
    }
}

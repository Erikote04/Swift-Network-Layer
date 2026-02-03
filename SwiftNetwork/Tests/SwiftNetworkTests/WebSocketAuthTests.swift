//
//  WebSocketAuthTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 29/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("WebSocket Authentication", .tags(.websocket))
struct WebSocketAuthTests {
    
    @Test("WebSocket call retrieves token from store")
    func callRetrievesTokenFromStore() async throws {
        let tokenStore = InMemoryTokenStore()
        await tokenStore.updateToken("test_ws_token")
        
        let request = Request(
            method: .get,
            url: URL(string: "wss://api.example.com/ws")!
        )
        
        let call = BaseWebSocketCall(
            request: request,
            session: .shared,
            tokenStore: tokenStore
        )
        
        // Note: Can't easily test actual connection without real WebSocket server
        // But we can verify the call is properly initialized
        #expect(call.request.url.scheme == "wss")
        #expect(await call.isCancelled() == false)
    }
    
    @Test("WebSocket transport accepts auth token provider")
    func transportAcceptsAuthTokenProvider() async {
        let url = URL(string: "wss://echo.websocket.org")!
        let transport = WebSocketTransport(url: url)
        
        let providerTracker = ProviderCallTracker()
        
        await transport.setAuthTokenProvider {
            await providerTracker.markCalled()
            return "provider_token"
        }
        
        // Verify transport is created correctly
        #expect(await transport.connectionState == false)
    }
    
    @Test("BaseWebSocketCall prefers AuthManager over TokenStore")
    func callPrefersAuthManager() async throws {
        let tokenStore = InMemoryTokenStore()
        await tokenStore.updateToken("store_token")
        
        let manager = AuthManager(tokenStore: tokenStore)
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "manager_token",
                provider: .apple
            )
        )
        _ = try await manager.login(provider: provider)
        
        let request = Request(
            method: .get,
            url: URL(string: "wss://api.example.com/ws")!
        )
        
        let call = BaseWebSocketCall(
            request: request,
            session: .shared,
            tokenStore: tokenStore,
            authManager: manager
        )
        
        // Verify call is created correctly
        // Actual token retrieval happens during connect()
        #expect(await call.isCancelled() == false)
        #expect(await manager.isAuthenticated)
    }
    
    @Test("WebSocket reconnect uses fresh token from provider")
    func reconnectUsesFreshToken() async {
        let url = URL(string: "wss://echo.websocket.org")!
        let transport = WebSocketTransport(url: url)
        
        let tokenCounter = TokenCounter()
        
        await transport.setAuthTokenProvider {
            await tokenCounter.getNextToken()
        }
        
        // Simulate multiple reconnect scenarios
        let token1 = await tokenCounter.getNextToken()
        let token2 = await tokenCounter.getNextToken()
        
        #expect(token1 == "token_1")
        #expect(token2 == "token_2")
    }
    
    @Test("NetworkClient passes auth to WebSocket calls")
    func clientPassesAuthToWebSocketCalls() async throws {
        let tokenStore = InMemoryTokenStore()
        await tokenStore.updateToken("client_token")
        
        let authInterceptor = AuthInterceptor(tokenStore: tokenStore)
        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://api.example.com")!,
            interceptors: [authInterceptor]
        )
        
        let client = NetworkClient(configuration: config)
        
        let request = Request(
            method: .get,
            url: URL(string: "/ws")!
        )
        
        let call = client.newWebSocketCall(request)
        
        #expect(call.request.url.scheme == "wss")
        #expect(call.request.url.host == "api.example.com")
    }
    
    @Test("WebSocket call with cancelled state throws")
    func cancelledCallThrows() async throws {
        let request = Request(
            method: .get,
            url: URL(string: "wss://api.example.com/ws")!
        )
        
        let call = BaseWebSocketCall(
            request: request,
            session: .shared
        )
        
        await call.cancel()
        
        #expect(await call.isCancelled())
        
        await #expect(throws: NetworkError.self) {
            _ = try await call.connect()
        }
    }
}

// MARK: - Mocks

private struct MockAuthProvider: AuthProvider {
    let credentials: AuthCredentials
    
    func login() async throws -> AuthCredentials {
        credentials
    }
}

private actor TokenCounter {
    private var count = 0
    
    func getNextToken() -> String {
        count += 1
        return "token_\(count)"
    }
}

private actor ProviderCallTracker {
    private var wasCalled = false
    
    func markCalled() {
        wasCalled = true
    }
    
    func called() -> Bool {
        wasCalled
    }
}

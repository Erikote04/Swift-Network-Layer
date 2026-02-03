//
//  WebSocketEndToEndTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 3/2/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("WebSocket End-to-End", .tags(.websocket))
struct WebSocketEndToEndTests {
    
    @Test("Complete WebSocket lifecycle with NetworkClient")
    func completeLifecycleWithClient() async throws {
        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://api.example.com")!
        )
        let client = NetworkClient(configuration: config)
        
        let request = Request(
            method: .get,
            url: URL(string: "/ws/echo")!
        )
        
        let call = client.newWebSocketCall(request)
        
        // Verify URL resolution
        #expect(call.request.url.scheme == "wss")
        #expect(call.request.url.host == "api.example.com")
        #expect(call.request.url.path == "/ws/echo")
        
        // Verify call is not cancelled
        #expect(await call.isCancelled() == false)
    }
    
    @Test("WebSocket with authentication flow")
    func webSocketWithAuthentication() async throws {
        let tokenStore = InMemoryTokenStore()
        await tokenStore.updateToken("auth_token_123")
        
        let authInterceptor = AuthInterceptor(tokenStore: tokenStore)
        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://api.example.com")!,
            interceptors: [authInterceptor]
        )
        
        let client = NetworkClient(configuration: config)
        
        let request = Request(
            method: .get,
            url: URL(string: "/ws/chat")!
        )
        
        let call = client.newWebSocketCall(request)
        
        // Verify request is properly configured
        #expect(call.request.url.scheme == "wss")
        #expect(await call.isCancelled() == false)
    }
    
    @Test("WebSocket with auto-reconnect configuration")
    func webSocketWithAutoReconnect() async {
        let url = URL(string: "wss://echo.websocket.org")!
        let transport = WebSocketTransport(url: url)
        
        // Configure auto-reconnect
        await transport.enableAutoReconnect(
            maxAttempts: 3,
            initialDelay: 1.0,
            maxDelay: 10.0,
            multiplier: 2.0
        )
        
        // Verify transport is configured
        #expect(await transport.connectionState == false)
    }
    
    @Test("WebSocket with monitoring and auto-reconnect")
    func webSocketWithMonitoringAndReconnect() async {
        let url = URL(string: "wss://echo.websocket.org")!
        let transport = WebSocketTransport(url: url)
        
        // Configure both features
        await transport.enableAutoReconnect(maxAttempts: 3)
        transport.enableConnectionMonitoring(
            pingInterval: 30.0,
            pongTimeout: 10.0
        )
        
        // Give time for async configuration
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Verify transport is configured
        #expect(await transport.connectionState == false)
    }
    
    @Test("WebSocket cancellation during connection")
    func cancellationDuringConnection() async throws {
        let request = Request(
            method: .get,
            url: URL(string: "wss://api.example.com/ws")!
        )
        
        let call = BaseWebSocketCall(
            request: request,
            session: .shared
        )
        
        // Cancel before connecting
        await call.cancel()
        
        #expect(await call.isCancelled())
        
        // Attempting to connect should throw
        await #expect(throws: NetworkError.self) {
            _ = try await call.connect()
        }
    }
    
    @Test("WebSocket with AuthManager integration")
    func webSocketWithAuthManager() async throws {
        let tokenStore = InMemoryTokenStore()
        let authManager = AuthManager(tokenStore: tokenStore)
        
        // Simulate login
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "manager_token",
                refreshToken: "refresh_token",
                expiresIn: 3600,
                provider: .apple
            )
        )
        
        _ = try await authManager.login(provider: provider)
        
        let request = Request(
            method: .get,
            url: URL(string: "wss://api.example.com/ws")!
        )
        
        let call = BaseWebSocketCall(
            request: request,
            session: .shared,
            authManager: authManager
        )
        
        // Verify call is properly configured
        #expect(await call.isCancelled() == false)
        #expect(await authManager.isAuthenticated)
    }
    
    @Test("WebSocket URL scheme conversion from HTTP to WS")
    func urlSchemeConversion() {
        let httpURL = URL(string: "http://localhost:8080/ws")!
        let httpsURL = URL(string: "https://api.example.com/ws")!
        
        let config = NetworkClientConfiguration(
            baseURL: httpURL
        )
        let client = NetworkClient(configuration: config)
        
        let request = Request(
            method: .get,
            url: URL(string: "/chat")!
        )
        
        let call = client.newWebSocketCall(request)
        
        // HTTP should convert to WS
        #expect(call.request.url.scheme == "ws")
        
        // Test HTTPS to WSS
        let secureConfig = NetworkClientConfiguration(
            baseURL: httpsURL
        )
        let secureClient = NetworkClient(configuration: secureConfig)
        let secureCall = secureClient.newWebSocketCall(request)
        
        #expect(secureCall.request.url.scheme == "wss")
    }
    
    @Test("WebSocket message types are preserved")
    func messageTypesPreserved() {
        let textMessage = WebSocketMessage.text("Hello, WebSocket!")
        #expect(textMessage.isText)
        #expect(!textMessage.isBinary)
        #expect(textMessage.string == "Hello, WebSocket!")
        
        let binaryData = Data([0x01, 0x02, 0x03])
        let binaryMessage = WebSocketMessage.binary(binaryData)
        #expect(binaryMessage.isBinary)
        #expect(!binaryMessage.isText)
        #expect(binaryMessage.data == binaryData)
    }
    
    @Test("WebSocket error handling and types")
    func errorHandlingAndTypes() {
        let errors: [WebSocketError] = [
            .connectionFailed("Network error"),
            .connectionClosed(code: 1000, reason: "Normal closure"),
            .alreadyClosed,
            .cancelled,
            .sendFailed("Send error"),
            .receiveFailed("Receive error"),
            .invalidMessage,
            .transportError("Transport error")
        ]
        
        for error in errors {
            // All errors should have descriptions
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - Test Helpers

private struct MockAuthProvider: AuthProvider {
    let credentials: AuthCredentials
    
    func login() async throws -> AuthCredentials {
        credentials
    }
}

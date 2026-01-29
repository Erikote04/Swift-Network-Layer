//
//  WebSocketIntegrationTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 29/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("WebSocket Integration")
struct WebSocketIntegrationTests {
    
    @Test("BaseWebSocketCall creates transport")
    func baseCallCreatesTransport() async throws {
        let url = URL(string: "wss://echo.websocket.org")!
        let request = Request(method: .get, url: url)
        
        let call = BaseWebSocketCall(
            request: request,
            session: .shared,
            tokenStore: nil
        )
        
        #expect(call.request.url == url)
        #expect(!call.isCancelled)
    }
    
    @Test("BaseWebSocketCall cancellation")
    func baseCallCancellation() async throws {
        let url = URL(string: "wss://echo.websocket.org")!
        let request = Request(method: .get, url: url)
        
        let call = BaseWebSocketCall(
            request: request,
            session: .shared,
            tokenStore: nil
        )
        
        #expect(!call.isCancelled)
        
        call.cancel()
        
        #expect(call.isCancelled)
        
        // Connecting after cancel should throw
        await #expect(throws: NetworkError.self) {
            _ = try await call.connect()
        }
    }
    
    @Test("NetworkClient WebSocket URL resolution with base URL")
    func clientWebSocketURLResolution() {
        let baseURL = URL(string: "https://api.example.com")!
        let config = NetworkClientConfiguration(baseURL: baseURL)
        let client = NetworkClient(configuration: config)
        
        let request = Request(
            method: .get,
            url: URL(string: "/ws/chat")!
        )
        
        let call = client.newWebSocketCall(request)
        
        // Should resolve to wss://api.example.com/ws/chat
        #expect(call.request.url.scheme == "wss")
        #expect(call.request.url.host == "api.example.com")
        #expect(call.request.url.path == "/ws/chat")
    }
    
    @Test("NetworkClient WebSocket HTTP to WS scheme conversion")
    func clientSchemeConversion() {
        let baseURL = URL(string: "http://localhost:8080")!
        let config = NetworkClientConfiguration(baseURL: baseURL)
        let client = NetworkClient(configuration: config)
        
        let request = Request(
            method: .get,
            url: URL(string: "/ws")!
        )
        
        let call = client.newWebSocketCall(request)
        
        // Should convert http to ws
        #expect(call.request.url.scheme == "ws")
    }
    
    @Test("NetworkClient WebSocket HTTPS to WSS scheme conversion")
    func clientSecureSchemeConversion() {
        let baseURL = URL(string: "https://api.example.com")!
        let config = NetworkClientConfiguration(baseURL: baseURL)
        let client = NetworkClient(configuration: config)
        
        let request = Request(
            method: .get,
            url: URL(string: "/ws")!
        )
        
        let call = client.newWebSocketCall(request)
        
        // Should convert https to wss
        #expect(call.request.url.scheme == "wss")
    }
    
    @Test("NetworkClient WebSocket preserves existing WS scheme")
    func clientPreservesWSScheme() {
        let client = NetworkClient()
        
        let request = Request(
            method: .get,
            url: URL(string: "ws://localhost:8080/ws")!
        )
        
        let call = client.newWebSocketCall(request)
        
        // Should preserve ws scheme
        #expect(call.request.url.scheme == "ws")
    }
    
    @Test("NetworkClient WebSocket merges default headers")
    func clientMergesHeaders() {
        let config = NetworkClientConfiguration(
            defaultHeaders: [
                "X-API-Key": "secret",
                "X-Client-Version": "1.0"
            ]
        )
        let client = NetworkClient(configuration: config)
        
        let request = Request(
            method: .get,
            url: URL(string: "wss://api.example.com/ws")!,
            headers: ["X-Custom": "value"]
        )
        
        let call = client.newWebSocketCall(request)
        
        #expect(call.request.headers["X-API-Key"] == "secret")
        #expect(call.request.headers["X-Client-Version"] == "1.0")
        #expect(call.request.headers["X-Custom"] == "value")
    }
    
    @Test("NetworkClient WebSocket removes body")
    func clientRemovesBody() {
        let client = NetworkClient()
        
        let request = Request(
            method: .get,
            url: URL(string: "wss://api.example.com/ws")!,
            body: .json(["key": "value"])
        )
        
        let call = client.newWebSocketCall(request)
        
        // WebSocket requests should not have a body
        #expect(call.request.body == nil)
    }
    
    @Test("NetworkClient WebSocket ignores cache policy")
    func clientIgnoresCachePolicy() {
        let client = NetworkClient()
        
        let request = Request(
            method: .get,
            url: URL(string: "wss://api.example.com/ws")!,
            cachePolicy: .useCache
        )
        
        let call = client.newWebSocketCall(request)
        
        // WebSocket requests should ignore cache
        #expect(call.request.cachePolicy == .ignoreCache)
    }
}

//
//  WebSocketCall.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 29/1/26.
//

import Foundation

/// A protocol for calls that establish WebSocket connections.
///
/// `WebSocketCall` extends the base `Call` protocol to support
/// WebSocket-specific operations like connection establishment,
/// message streaming, and graceful closure.
///
/// Unlike standard HTTP calls that complete with a single response,
/// WebSocket calls maintain a persistent bidirectional connection
/// for real-time communication.
public protocol WebSocketCall: Call {
    
    /// Establishes a WebSocket connection.
    ///
    /// This method initiates the WebSocket handshake and returns
    /// a `WebSocketTransport` instance for bidirectional communication.
    ///
    /// - Returns: A connected `WebSocketTransport`.
    /// - Throws: `WebSocketError` if the connection fails.
    func connect() async throws -> WebSocketTransport
}

// MARK: - Default Implementation

extension WebSocketCall {
    
    /// Default implementation that throws an error.
    ///
    /// WebSocket calls should not use the standard `execute()` method.
    /// Use `connect()` instead.
    ///
    /// - Throws: `NetworkError.transportError` always.
    public func execute() async throws -> Response {
        throw NetworkError.transportError(
            WebSocketError.connectionFailed("Use connect() for WebSocket calls")
        )
    }
}

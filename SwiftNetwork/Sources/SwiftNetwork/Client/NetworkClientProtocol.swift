//
//  NetworkClientProtocol.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A protocol defining the core capabilities of a network client.
///
/// `NetworkClientProtocol` is the main interface for creating and executing
/// network operations. Implementations manage configuration, interceptors,
/// and transport coordination.
public protocol NetworkClientProtocol: Sendable {

    /// Creates a new executable network call for the given request.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `Call` representing the executable request.
    func newCall(_ request: Request) -> Call
    
    /// Creates a new WebSocket call for the given request.
    ///
    /// WebSocket calls establish persistent bidirectional connections
    /// for real-time communication.
    ///
    /// - Parameter request: The WebSocket connection request.
    /// - Returns: A `WebSocketCall` that can be used to establish the connection.
    func newWebSocketCall(_ request: Request) -> WebSocketCall
}

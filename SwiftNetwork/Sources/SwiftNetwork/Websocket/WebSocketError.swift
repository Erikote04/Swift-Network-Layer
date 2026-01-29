//
//  WebSocketError.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 29/1/26.
//

import Foundation

/// Errors that can occur during WebSocket operations.
///
/// `WebSocketError` provides detailed error information for connection,
/// communication, and lifecycle failures in WebSocket operations.
public enum WebSocketError: Error, Sendable {
    
    /// The WebSocket connection failed to establish.
    ///
    /// - Parameter reason: A description of why the connection failed.
    case connectionFailed(String)
    
    /// The WebSocket connection was closed.
    ///
    /// - Parameters:
    ///   - code: The close code sent by the peer or system.
    ///   - reason: An optional human-readable reason for closure.
    case connectionClosed(code: Int, reason: String?)
    
    /// An operation was attempted on a closed WebSocket.
    case alreadyClosed
    
    /// The WebSocket connection was cancelled.
    case cancelled
    
    /// Failed to send a message over the WebSocket.
    ///
    /// - Parameter description: Error description.
    case sendFailed(String)
    
    /// Failed to receive a message from the WebSocket.
    ///
    /// - Parameter description: Error description.
    case receiveFailed(String)
    
    /// An invalid message was received.
    ///
    /// This may occur if the peer sends malformed data or an unexpected
    /// message type.
    case invalidMessage
    
    /// A general transport-level error occurred.
    ///
    /// - Parameter description: Error description.
    case transportError(String)
}

extension WebSocketError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "WebSocket connection failed: \(reason)"
        case .connectionClosed(let code, let reason):
            let reasonText = reason ?? "no reason provided"
            return "WebSocket closed with code \(code): \(reasonText)"
        case .alreadyClosed:
            return "Operation attempted on closed WebSocket"
        case .cancelled:
            return "WebSocket operation was cancelled"
        case .sendFailed(let description):
            return "Failed to send WebSocket message: \(description)"
        case .receiveFailed(let description):
            return "Failed to receive WebSocket message: \(description)"
        case .invalidMessage:
            return "Received invalid WebSocket message"
        case .transportError(let description):
            return "WebSocket transport error: \(description)"
        }
    }
}

extension WebSocketError: Equatable {
    public static func == (lhs: WebSocketError, rhs: WebSocketError) -> Bool {
        switch (lhs, rhs) {
        case (.connectionFailed(let l), .connectionFailed(let r)):
            return l == r
        case (.connectionClosed(let lCode, let lReason), .connectionClosed(let rCode, let rReason)):
            return lCode == rCode && lReason == rReason
        case (.alreadyClosed, .alreadyClosed),
             (.cancelled, .cancelled),
             (.invalidMessage, .invalidMessage):
            return true
        case (.sendFailed(let l), .sendFailed(let r)),
             (.receiveFailed(let l), .receiveFailed(let r)),
             (.transportError(let l), .transportError(let r)):
            return l == r
        default:
            return false
        }
    }
}

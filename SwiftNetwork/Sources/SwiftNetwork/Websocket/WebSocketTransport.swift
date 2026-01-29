//
//  WebSocketTransport.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 29/1/26.
//

import Foundation

/// A WebSocket transport providing real-time bidirectional communication.
///
/// `WebSocketTransport` manages a WebSocket connection lifecycle, including:
/// - Connection establishment and authentication
/// - Message sending and receiving
/// - Automatic reconnection with exponential backoff
/// - Graceful connection closure
public actor WebSocketTransport {
    
    // MARK: - Properties
    
    /// The WebSocket connection URL.
    public let url: URL
    
    /// The underlying URLSession used for WebSocket connections.
    private let session: URLSession
    
    /// The active WebSocket task, if connected.
    private var webSocketTask: URLSessionWebSocketTask?
    
    /// Continuation for the message stream.
    private var messageContinuation: AsyncStream<WebSocketMessage>.Continuation?
    
    /// Current connection state.
    private var isConnected = false
    
    /// Indicates if the connection was explicitly closed by the client.
    private var explicitlyClosed = false
    
    // MARK: - Auto-Reconnect Configuration
    
    /// Auto-reconnect configuration.
    private var reconnectConfig: ReconnectConfig?
    
    /// Current reconnect attempt count.
    private var reconnectAttempts = 0
    
    /// Auth token to use on reconnect.
    private var authToken: String?
    
    // MARK: - Initialization
    
    /// Creates a new WebSocket transport.
    ///
    /// - Parameters:
    ///   - url: The WebSocket server URL (must use `ws://` or `wss://` scheme).
    ///   - session: The URLSession to use for the WebSocket connection.
    ///     Defaults to `.shared`.
    public init(
        url: URL,
        session: URLSession = .shared
    ) {
        self.url = url
        self.session = session
    }
    
    // MARK: - Connection Management
    
    /// Establishes a WebSocket connection.
    ///
    /// If auto-reconnect is enabled and a previous connection exists,
    /// this will attempt to reconnect with the configured backoff strategy.
    ///
    /// - Parameter authToken: Optional authentication token to include
    ///   in the connection request headers.
    /// - Throws: `WebSocketError.connectionFailed` if the connection
    ///   cannot be established.
    public func connect(authToken: String? = nil) async throws {
        self.authToken = authToken
        self.explicitlyClosed = false
        
        var request = URLRequest(url: url)
        
        // Add auth header if provided
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create WebSocket task
        let task = session.webSocketTask(with: request)
        self.webSocketTask = task
        
        // Start the connection
        task.resume()
        
        // Start receiving messages
        startReceiving()
        
        self.isConnected = true
        self.reconnectAttempts = 0
    }
    
    /// Closes the WebSocket connection gracefully.
    ///
    /// This sends a close frame to the peer and cleans up resources.
    ///
    /// - Parameters:
    ///   - code: The close code to send. Defaults to `.normalClosure`.
    ///   - reason: An optional reason string for the closure.
    public func close(
        code: URLSessionWebSocketTask.CloseCode = .normalClosure,
        reason: String? = nil
    ) async {
        explicitlyClosed = true
        isConnected = false
        
        let reasonData = reason?.data(using: .utf8)
        webSocketTask?.cancel(with: code, reason: reasonData)
        webSocketTask = nil
        
        messageContinuation?.finish()
        messageContinuation = nil
    }
    
    // MARK: - Sending Messages
    
    /// Sends a message over the WebSocket connection.
    ///
    /// - Parameter message: The message to send.
    /// - Throws: `WebSocketError.alreadyClosed` if the connection is closed,
    ///   or `WebSocketError.sendFailed` if the send operation fails.
    public func send(_ message: WebSocketMessage) async throws {
        guard let task = webSocketTask, isConnected else {
            throw WebSocketError.alreadyClosed
        }
        
        let urlMessage: URLSessionWebSocketTask.Message
        
        switch message {
        case .text(let string):
            urlMessage = .string(string)
        case .binary(let data):
            urlMessage = .data(data)
        }
        
        do {
            try await task.send(urlMessage)
        } catch is CancellationError {
            throw WebSocketError.cancelled
        } catch {
            throw WebSocketError.sendFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Receiving Messages
    
    /// An asynchronous stream of incoming WebSocket messages.
    ///
    /// Messages are delivered as they arrive from the server.
    /// The stream completes when the connection is closed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// for try await message in webSocket.messages {
    ///     switch message {
    ///     case .text(let content):
    ///         print("Text: \(content)")
    ///     case .binary(let data):
    ///         print("Binary: \(data.count) bytes")
    ///     }
    /// }
    /// ```
    public var messages: AsyncStream<WebSocketMessage> {
        AsyncStream { continuation in
            self.messageContinuation = continuation
        }
    }
    
    /// Starts the message receiving loop.
    private func startReceiving() {
        Task {
            await receiveNextMessage()
        }
    }
    
    /// Receives the next message from the WebSocket.
    private func receiveNextMessage() async {
        guard let task = webSocketTask, isConnected else { return }
        
        do {
            let message = try await task.receive()
            
            let swiftNetworkMessage: WebSocketMessage
            
            switch message {
            case .string(let text):
                swiftNetworkMessage = .text(text)
            case .data(let data):
                swiftNetworkMessage = .binary(data)
            @unknown default:
                // Handle future message types
                return
            }
            
            messageContinuation?.yield(swiftNetworkMessage)
            
            // Continue receiving
            await receiveNextMessage()
            
        } catch is CancellationError {
            await handleDisconnection(reason: "Connection cancelled")
        } catch {
            await handleDisconnection(reason: error.localizedDescription)
        }
    }
    
    // MARK: - Auto-Reconnect
    
    /// Enables automatic reconnection with exponential backoff.
    ///
    /// When enabled, the transport will automatically attempt to reconnect
    /// if the connection is lost unexpectedly (not due to explicit closure).
    ///
    /// - Parameters:
    ///   - maxAttempts: Maximum number of reconnection attempts.
    ///     Use `nil` for unlimited attempts.
    ///   - initialDelay: Initial delay before the first reconnect attempt.
    ///     Defaults to 1 second.
    ///   - maxDelay: Maximum delay between reconnect attempts.
    ///     Defaults to 30 seconds.
    ///   - multiplier: Backoff multiplier for exponential delay.
    ///     Defaults to 2.0.
    public func enableAutoReconnect(
        maxAttempts: Int? = nil,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        multiplier: Double = 2.0
    ) {
        self.reconnectConfig = ReconnectConfig(
            maxAttempts: maxAttempts,
            initialDelay: initialDelay,
            maxDelay: maxDelay,
            multiplier: multiplier
        )
    }
    
    /// Disables automatic reconnection.
    public func disableAutoReconnect() {
        self.reconnectConfig = nil
    }
    
    /// Handles connection loss and triggers reconnection if enabled.
    private func handleDisconnection(reason: String) async {
        isConnected = false
        messageContinuation?.finish()
        messageContinuation = nil
        
        // Don't reconnect if explicitly closed
        guard !explicitlyClosed, let config = reconnectConfig else {
            return
        }
        
        // Check max attempts
        if let maxAttempts = config.maxAttempts,
           reconnectAttempts >= maxAttempts {
            return
        }
        
        // Calculate backoff delay
        let delay = min(
            config.initialDelay * pow(config.multiplier, Double(reconnectAttempts)),
            config.maxDelay
        )
        
        reconnectAttempts += 1
        
        // Wait before reconnecting
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Attempt reconnection
        try? await connect(authToken: authToken)
    }
    
    // MARK: - State
    
    /// Indicates whether the WebSocket is currently connected.
    public var connectionState: Bool {
        isConnected
    }
}

// MARK: - Reconnect Configuration

extension WebSocketTransport {
    
    /// Configuration for automatic reconnection behavior.
    struct ReconnectConfig: Sendable {
        let maxAttempts: Int?
        let initialDelay: TimeInterval
        let maxDelay: TimeInterval
        let multiplier: Double
    }
}

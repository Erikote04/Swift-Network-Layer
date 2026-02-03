//
//  BaseWebSocketCall.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 28/1/26.
//

import Foundation

/// A concrete implementation of `WebSocketCall`.
///
/// `BaseWebSocketCall` handles the lifecycle of a WebSocket connection,
/// including URL resolution, authentication header injection, and
/// connection establishment.
///
/// ## Overview
///
/// This implementation:
/// - Resolves WebSocket URLs against base configuration
/// - Applies authentication headers automatically
/// - Supports cancellation
/// - Provides connection state tracking
/// - Integrates with `AuthManager` for automatic token refresh during reconnection
public actor BaseWebSocketCall: WebSocketCall {
    
    // MARK: - Properties
    
    /// The request associated with this call.
    nonisolated public let request: Request
    
    /// The URLSession used for the WebSocket connection.
    private let session: URLSession
    
    /// Optional token store for authentication.
    private let tokenStore: TokenStore?
    
    /// Optional auth manager for token refresh during reconnection.
    private let authManager: AuthManager?
    
    /// The active WebSocket transport, if connected.
    private var transport: WebSocketTransport?
    
    /// Cancellation state.
    private var isCancelledFlag = false
    
    // MARK: - Initialization
    
    /// Creates a new WebSocket call.
    ///
    /// - Parameters:
    ///   - request: The WebSocket connection request.
    ///   - session: The URLSession to use for the connection.
    ///   - tokenStore: Optional token store for authentication.
    ///   - authManager: Optional auth manager for token refresh.
    public init(
        request: Request,
        session: URLSession = .shared,
        tokenStore: TokenStore? = nil,
        authManager: AuthManager? = nil
    ) {
        self.request = request
        self.session = session
        self.tokenStore = tokenStore
        self.authManager = authManager
    }
    
    // MARK: - WebSocketCall
    
    /// Establishes a WebSocket connection.
    ///
    /// This method:
    /// 1. Checks for cancellation
    /// 2. Retrieves authentication token if available
    /// 3. Creates a WebSocket transport
    /// 4. Sets up auth token provider for reconnection
    /// 5. Initiates the connection
    ///
    /// - Returns: A connected `WebSocketTransport`.
    /// - Throws: `NetworkError.cancelled` if the call was cancelled,
    ///   or `WebSocketError` if the connection fails.
    public func connect() async throws -> WebSocketTransport {
        // Check cancellation
        guard !isCancelledFlag else {
            throw NetworkError.cancelled
        }
        
        // Get auth token - prefer authManager over tokenStore
        let authToken: String?
        if let manager = authManager {
            authToken = await manager.currentCredentials?.accessToken
        } else {
            authToken = await tokenStore?.currentToken()
        }
        
        // Create transport
        let wsTransport = WebSocketTransport(
            url: request.url,
            session: session
        )
        
        // Set up auth token provider for reconnection if we have an auth manager
        if let manager = authManager {
            await wsTransport.setAuthTokenProvider {
                await manager.currentCredentials?.accessToken
            }
        } else if let store = tokenStore {
            await wsTransport.setAuthTokenProvider {
                await store.currentToken()
            }
        }
        
        // Store reference
        transport = wsTransport
        
        // Check cancellation before connecting
        guard !isCancelledFlag else {
            throw NetworkError.cancelled
        }
        
        // Connect
        try await wsTransport.connect(authToken: authToken)
        
        return wsTransport
    }
    
    // MARK: - Call
    
    /// Cancels the WebSocket call.
    ///
    /// If a connection is active, it will be closed gracefully.
    public func cancel() async {
        isCancelledFlag = true
        await transport?.close(
            code: .goingAway,
            reason: "Call cancelled"
        )
    }
    
    /// Indicates whether the call has been cancelled.
    public func isCancelled() async -> Bool {
        isCancelledFlag
    }
}

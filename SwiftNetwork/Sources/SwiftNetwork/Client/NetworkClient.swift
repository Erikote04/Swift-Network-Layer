//
//  NetworkClient.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// The main entry point of the SwiftNetwork framework.
///
/// `NetworkClient` is responsible for creating and executing network calls.
/// It applies global configuration such as base URL resolution, default headers,
/// interceptors with priority and request/response separation support,
/// certificate pinning, request deduplication, and transport selection.
///
/// A single `NetworkClient` instance is intended to be reused across the
/// application lifecycle.
public final class NetworkClient: NetworkClientProtocol {
    
    private let configuration: NetworkClientConfiguration
    private let transport: Transport
    private let authCoordinator = AuthRefreshCoordinator()
    private let deduplicator: RequestDeduplicator?
    
    /// Creates a network client using a custom transport and a set of interceptors.
    ///
    /// This initializer is intended for internal usage and testing.
    ///
    /// - Parameters:
    ///   - transport: The transport responsible for executing requests.
    ///   - interceptors: The interceptors applied to every request.
    init(
        transport: Transport,
        interceptors: [Interceptor]
    ) {
        self.configuration = NetworkClientConfiguration(interceptors: interceptors)
        self.transport = transport
        self.deduplicator = nil
    }
    
    /// Creates a network client with a given configuration and URL session.
    ///
    /// - Parameters:
    ///   - configuration: Defines base URL, default headers, timeout, interceptors, and pinning.
    ///   - session: The URLSession used by the underlying transport.
    public init(
        configuration: NetworkClientConfiguration = .init(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.transport = URLSessionTransport(
            session: session,
            certificatePinner: configuration.certificatePinner
        )
        self.deduplicator = configuration.enableDeduplication ? RequestDeduplicator() : nil
    }
    
    /// Creates a new executable network call for the given request.
    ///
    /// The request is resolved against the client configuration before execution.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `Call` representing the executable request.
    public func newCall(_ request: Request) -> Call {
        let resolvedRequest = resolve(request)
        
        let baseCall = InterceptorCall(
            request: resolvedRequest,
            interceptors: resolvedInterceptors(),
            transport: transport
        )
        
        // Wrap with deduplication if enabled
        if let deduplicator = deduplicator {
            return DeduplicatedCall(
                baseCall: baseCall,
                deduplicator: deduplicator
            )
        }
        
        return baseCall
    }
    
    /// Resolves interceptors for a call, injecting shared coordination when required.
    ///
    /// This merges regular, prioritized, request-only, and response-only interceptors,
    /// sorting by priority and ensuring proper authentication coordination.
    ///
    /// - Returns: The list of interceptors to be applied to the call.
    private func resolvedInterceptors() -> [Interceptor] {
        // 1. Prioritized interceptors (sorted by priority)
        let prioritized = configuration.prioritizedInterceptors
            .sorted()
            .map { $0.interceptor }
        
        // 2. Request-only interceptors (adapted to full Interceptor)
        let requestAdapted = configuration.requestInterceptors
            .map { RequestResponseInterceptorAdapter(requestInterceptor: $0) }
        
        // 3. Regular interceptors (as-is)
        let regular = configuration.interceptors
        
        // 4. Response-only interceptors (adapted to full Interceptor)
        let responseAdapted = configuration.responseInterceptors
            .map { RequestResponseInterceptorAdapter(responseInterceptor: $0) }
        
        // Combine: prioritized → request → regular → response
        let allInterceptors = prioritized + requestAdapted + regular + responseAdapted
        
        return allInterceptors.map { interceptor in
            // Inject coordinator for legacy AuthInterceptor (with authenticator)
            if let authInterceptor = interceptor as? AuthInterceptor {
                // Only recreate if it has an authenticator (legacy path)
                if authInterceptor.authenticator != nil {
                    return AuthInterceptor(
                        tokenStore: authInterceptor.tokenStore,
                        authenticator: authInterceptor.authenticator,
                        coordinator: authCoordinator
                    )
                }
            }
            
            return interceptor
        }
    }
    
    /// Resolves a request by applying global configuration.
    ///
    /// This includes base URL resolution, default headers merging,
    /// timeout resolution, and cache policy preservation.
    ///
    /// - Parameter request: The original request.
    /// - Returns: A fully resolved request ready for execution.
    private func resolve(_ request: Request) -> Request {
        var finalURL = request.url
        
        if let baseURL = configuration.baseURL,
           request.url.host == nil {
            finalURL = baseURL.appendingPathComponent(request.url.path)
        }
        
        let headers = configuration
            .defaultHeaders
            .merging(request.headers)
        
        let timeout = request.timeout ?? configuration.timeout
        
        return Request(
            method: request.method,
            url: finalURL,
            headers: headers,
            body: request.body,
            timeout: timeout,
            cachePolicy: request.cachePolicy,
            priority: request.priority
        )
    }
    
    // MARK: - WebSocket Support
    
    /// Creates a new WebSocket call for the given request.
    ///
    /// WebSocket calls establish a persistent bidirectional connection
    /// for real-time communication. Unlike standard HTTP calls, WebSocket
    /// calls maintain an open connection after establishment.
    ///
    /// ## URL Resolution
    ///
    /// If the request URL is relative (no host), it will be resolved
    /// against the client's base URL. The scheme is automatically converted:
    /// - `http://` → `ws://`
    /// - `https://` → `wss://`
    ///
    /// ## Authentication
    ///
    /// If an `AuthInterceptor` is configured, the WebSocket call will
    /// automatically include authentication tokens in the connection headers.
    ///
    /// - Parameter request: The WebSocket connection request.
    /// - Returns: A `WebSocketCall` that can be used to establish the connection.
    public func newWebSocketCall(_ request: Request) -> WebSocketCall {
        let resolvedRequest = resolveWebSocketRequest(request)
        
        return BaseWebSocketCall(
            request: resolvedRequest,
            session: extractSession(),
            tokenStore: extractTokenStore()
        )
    }
    
    // MARK: - WebSocket Private Helpers
    
    /// Resolves a WebSocket request against the client configuration.
    ///
    /// - Parameter request: The original request.
    /// - Returns: A resolved request with WebSocket URL scheme.
    private func resolveWebSocketRequest(_ request: Request) -> Request {
        var finalURL = request.url
        
        // Resolve against base URL if needed
        if let baseURL = configuration.baseURL,
           request.url.host == nil {
            finalURL = baseURL.appendingPathComponent(request.url.path)
        }
        
        // Convert HTTP scheme to WebSocket scheme
        if let scheme = finalURL.scheme {
            let wsScheme: String
            switch scheme.lowercased() {
            case "http":
                wsScheme = "ws"
            case "https":
                wsScheme = "wss"
            default:
                wsScheme = scheme  // Already ws/wss or custom
            }
            
            var components = URLComponents(url: finalURL, resolvingAgainstBaseURL: false)
            components?.scheme = wsScheme
            
            if let newURL = components?.url {
                finalURL = newURL
            }
        }
        
        // Merge headers (but not body - WebSocket upgrade is handled by URLSession)
        let headers = configuration
            .defaultHeaders
            .merging(request.headers)
        
        return Request(
            method: request.method,
            url: finalURL,
            headers: headers,
            body: nil,  // WebSocket connections don't have a body
            timeout: request.timeout ?? configuration.timeout,
            cachePolicy: .ignoreCache,  // WebSockets don't use cache
            priority: request.priority
        )
    }
    
    /// Extracts the URLSession from the transport or creates a default one.
    ///
    /// - Returns: A URLSession instance for WebSocket connections.
    private func extractSession() -> URLSession {
        // Try to extract session from URLSessionTransport
        if let urlSessionTransport = transport as? URLSessionTransport {
            // For now, return shared since URLSessionTransport doesn't expose its session
            // This can be enhanced later if needed
            return .shared
        }
        
        return .shared
    }
    
    /// Extracts the token store from configured interceptors.
    ///
    /// - Returns: The token store if an AuthInterceptor is configured.
    private func extractTokenStore() -> TokenStore? {
        // Check prioritized interceptors
        for prioritized in configuration.prioritizedInterceptors {
            if let authInterceptor = prioritized.interceptor as? AuthInterceptor {
                return authInterceptor.tokenStore
            }
        }
        
        // Check regular interceptors
        for interceptor in configuration.interceptors {
            if let authInterceptor = interceptor as? AuthInterceptor {
                return authInterceptor.tokenStore
            }
        }
        
        return nil
    }
}

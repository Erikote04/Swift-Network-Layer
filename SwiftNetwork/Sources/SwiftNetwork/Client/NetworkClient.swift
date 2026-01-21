//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// The main entry point of the SwiftNetwork framework.
///
/// `NetworkClient` is responsible for creating and executing network calls.
/// It applies global configuration such as base URL resolution, default headers,
/// interceptors with priority support, certificate pinning, and transport selection.
///
/// A single `NetworkClient` instance is intended to be reused across the
/// application lifecycle.
public final class NetworkClient: NetworkClientProtocol {

    private let configuration: NetworkClientConfiguration
    private let transport: Transport
    private let authCoordinator = AuthRefreshCoordinator()

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
    }

    /// Creates a new executable network call for the given request.
    ///
    /// The request is resolved against the client configuration before execution.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `Call` representing the executable request.
    public func newCall(_ request: Request) -> Call {
        let resolvedRequest = resolve(request)

        return InterceptorCall(
            request: resolvedRequest,
            interceptors: resolvedInterceptors(),
            transport: transport
        )
    }

    /// Resolves interceptors for a call, injecting shared coordination when required.
    ///
    /// This merges regular interceptors with prioritized ones, sorting by priority
    /// and ensuring proper authentication coordination.
    ///
    /// - Returns: The list of interceptors to be applied to the call.
    private func resolvedInterceptors() -> [Interceptor] {
        // Combine regular and prioritized interceptors
        let prioritized = configuration.prioritizedInterceptors
            .sorted()
            .map { $0.interceptor }
        
        let allInterceptors = prioritized + configuration.interceptors
        
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
    /// and timeout resolution.
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
            timeout: timeout
        )
    }
}

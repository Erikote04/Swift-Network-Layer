//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// Defines the global configuration applied to a `NetworkClient`.
///
/// This includes base URL resolution, default headers, request timeout,
/// interceptors with optional prioritization and request/response separation,
/// security configuration such as certificate pinning, and performance
/// optimizations like request deduplication.
public struct NetworkClientConfiguration: Sendable {

    /// The base URL used to resolve relative request paths.
    public let baseURL: URL?

    /// Headers automatically applied to every request.
    public let defaultHeaders: HTTPHeaders

    /// The default timeout interval for requests.
    public let timeout: TimeInterval

    /// The interceptors applied to all requests created by the client.
    ///
    /// Interceptors are executed in the order they appear in this array.
    /// Use `prioritizedInterceptors` for priority-based ordering.
    public let interceptors: [Interceptor]
    
    /// Prioritized interceptors applied to all requests.
    ///
    /// These interceptors are sorted by priority before execution,
    /// with higher priority values executing first.
    public let prioritizedInterceptors: [PrioritizedInterceptor]
    
    /// Request-only interceptors that modify outgoing requests.
    ///
    /// These execute before the request is sent to the transport.
    public let requestInterceptors: [RequestInterceptor]
    
    /// Response-only interceptors that process incoming responses.
    ///
    /// These execute after the transport returns a response.
    public let responseInterceptors: [ResponseInterceptor]
    
    /// The certificate pinner used to validate server certificates.
    ///
    /// When set, all HTTPS requests will be validated against the configured pins.
    /// If validation fails, the request will be rejected.
    public let certificatePinner: CertificatePinner?
    
    /// Enables request deduplication for identical in-flight requests.
    ///
    /// When enabled, multiple identical requests made concurrently will share
    /// a single network call, reducing bandwidth and server load.
    ///
    /// Defaults to `false` for backward compatibility.
    public let enableDeduplication: Bool

    /// Creates a new client configuration.
    ///
    /// - Parameters:
    ///   - baseURL: A base URL used to resolve relative paths.
    ///   - defaultHeaders: Headers added to every request.
    ///   - timeout: The default request timeout interval.
    ///   - interceptors: Interceptors applied to all requests.
    ///   - prioritizedInterceptors: Priority-based interceptors.
    ///   - requestInterceptors: Request-only interceptors.
    ///   - responseInterceptors: Response-only interceptors.
    ///   - certificatePinner: Optional certificate pinner for HTTPS requests.
    ///   - enableDeduplication: Enables request deduplication for identical in-flight requests.
    public init(
        baseURL: URL? = nil,
        defaultHeaders: HTTPHeaders = [:],
        timeout: TimeInterval = 60,
        interceptors: [Interceptor] = [],
        prioritizedInterceptors: [PrioritizedInterceptor] = [],
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = [],
        certificatePinner: CertificatePinner? = nil,
        enableDeduplication: Bool = false
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.interceptors = interceptors
        self.prioritizedInterceptors = prioritizedInterceptors
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.certificatePinner = certificatePinner
        self.enableDeduplication = enableDeduplication
    }
}

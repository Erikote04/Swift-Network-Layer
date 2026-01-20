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
/// interceptors, and security configuration such as certificate pinning.
public struct NetworkClientConfiguration: Sendable {

    /// The base URL used to resolve relative request paths.
    public let baseURL: URL?

    /// Headers automatically applied to every request.
    public let defaultHeaders: HTTPHeaders

    /// The default timeout interval for requests.
    public let timeout: TimeInterval

    /// The interceptors applied to all requests created by the client.
    public let interceptors: [Interceptor]
    
    /// The certificate pinner used to validate server certificates.
    ///
    /// When set, all HTTPS requests will be validated against the configured pins.
    /// If validation fails, the request will be rejected.
    public let certificatePinner: CertificatePinner?

    /// Creates a new client configuration.
    ///
    /// - Parameters:
    ///   - baseURL: A base URL used to resolve relative paths.
    ///   - defaultHeaders: Headers added to every request.
    ///   - timeout: The default request timeout interval.
    ///   - interceptors: Interceptors applied to all requests.
    ///   - certificatePinner: Optional certificate pinner for HTTPS requests.
    public init(
        baseURL: URL? = nil,
        defaultHeaders: HTTPHeaders = [:],
        timeout: TimeInterval = 60,
        interceptors: [Interceptor] = [],
        certificatePinner: CertificatePinner? = nil
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.interceptors = interceptors
        self.certificatePinner = certificatePinner
    }
}

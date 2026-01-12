//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// Defines an object capable of intercepting and modifying requests and responses.
///
/// Interceptors form a chain that can inspect, modify, retry, cache,
/// or short-circuit network requests.
public protocol Interceptor: Sendable {

    /// Intercepts a request and either returns a response or forwards the request.
    ///
    /// - Parameter chain: The interceptor chain.
    /// - Returns: A `Response`.
    /// - Throws: Any error produced during interception.
    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response
}

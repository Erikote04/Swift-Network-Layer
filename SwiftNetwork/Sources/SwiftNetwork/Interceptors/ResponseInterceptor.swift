//
//  ResponseInterceptor.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Foundation

/// A protocol for interceptors that only process incoming responses.
///
/// Response interceptors execute after the transport returns a response.
/// They can inspect or transform the response, log metrics, or handle
/// specific status codes without modifying the request.
public protocol ResponseInterceptor: Sendable {
    
    /// Intercepts and optionally processes an incoming response.
    ///
    /// - Parameters:
    ///   - response: The response to intercept.
    ///   - request: The original request that produced this response.
    /// - Returns: The potentially modified response.
    /// - Throws: Any error during response processing.
    func interceptResponse(_ response: Response, for request: Request) async throws -> Response
}

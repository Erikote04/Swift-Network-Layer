//
//  RequestInterceptor.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Foundation

/// A protocol for interceptors that only modify outgoing requests.
///
/// Request interceptors execute before the request is sent to the transport layer.
/// They can modify headers, body, URL, or other request properties without
/// handling the response.
public protocol RequestInterceptor: Sendable {
    
    /// Intercepts and optionally modifies an outgoing request.
    ///
    /// - Parameter request: The request to intercept.
    /// - Returns: The modified request.
    /// - Throws: Any error that prevents request processing.
    func interceptRequest(_ request: Request) async throws -> Request
}

//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// A protocol representing the interceptor execution chain.
///
/// Implementations manage the progression of a request through
/// multiple interceptors.
public protocol InterceptorChainProtocol: Sendable {

    /// The current request in the chain.
    var request: Request { get }

    /// Proceeds with the given request.
    ///
    /// - Parameter request: The request to forward.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced during execution.
    func proceed(_ request: Request) async throws -> Response
}
